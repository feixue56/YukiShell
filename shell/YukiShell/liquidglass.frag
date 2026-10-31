#version 440
// Liquid Glass for the yukidock Dock.
//
// Build:  qsb --qt6 -o liquidglass.frag.qsb liquidglass.frag
// (shell.qml runs this automatically on first use and caches the result in ~/.config/yukidock/)
//
// The shader treats the Dock as a slab of curved glass sitting on top of a live backdrop texture:
//   * a rounded-rect signed distance field gives the distance to the edge and the edge direction
//   * a convex "squircle" bezel profile turns that into a surface normal
//   * Snell's law (refract) turns the normal into a lateral shift of the sampled backdrop
//   * the backdrop is sampled per colour channel (dispersion) through a small disk blur
//   * saturation / adaptive tint / milky lift, then the Dock's measured edge light and a soft drop shadow

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;      // whole shader item in px (glass + pad on every side)
    vec2 glassSize;     // the Dock rectangle in px
    vec2 srcSize;       // backdrop texture size in px
    vec2 srcOffset;     // where the item's top-left sits inside the backdrop texture, px
    float pad;          // item padding around the glass (room for the drop shadow)
    float radius;       // corner radius, px
    float bezel;        // width of the refracting rim, px
    float thickness;    // how far the rim shifts the backdrop, px
    float dispersion;   // chromatic split (0 = none)
    float blurPx;       // backdrop blur radius, px
    float tintMix;      // 0..1 amount of flat tint (the "translucency" slider)
    float saturation;   // backdrop saturation boost
    float dark;         // 0 = light mode, 1 = dark mode
    float debug;        // 1 = show the raw backdrop texture (magenta = texture is empty)
    float rim;          // specular edge highlight strength (1 = original strength)
    float grain;        // fine noise amplitude over the whole glass
    float magnify;      // vertical lens magnification of the whole slab
    float shadowAmt;    // drop-shadow strength (1 = original, 0 = none) - appended last so older layouts stay compatible
    float rimTint;      // 0 = white rim (Dock / Menu Bar), 1 = rim + border take a brighter shade of the glass's own colour (widgets)
    float ringW;        // width in px of a thin border line along the very edge (0 = none)
    float flatInner;    // 1 = no inner edge shading (the darker inner rim); 0 = original. Appended last, unset = 0
    vec4 accentTint;    // rgb = the accent colour, a = 1 while "Tint the interface" is on. Appended last, unset = no tint
};

layout(binding = 1) uniform sampler2D src;

const int   TAPS   = 24;
const float GOLDEN = 2.39996323;

// Natural blur, no "duplicated background" ghosts:
//  * every tap reads a pre-blurred mip level sized to the gap between taps, so the taps overlap into one
//    smooth surface instead of showing as separate copies of the content
//  * Gaussian weights give a soft falloff instead of a hard disk edge
//  * the tap pattern is rotated per pixel (interleaved gradient noise), so any leftover gaps turn into
//    fine grain instead of repeating ghost lines
//  * one shared pattern for all three colour channels (dispersion only shifts the centre)
// Needs `mipmap: true` on the ShaderEffectSource (set in YukiBar.qml / YukiDock.qml).
vec3 backdropLod(vec2 pItem, float lod)
{
    vec2 uv = (pItem + srcOffset) / srcSize;
    return textureLod(src, clamp(uv, vec2(0.001), vec2(0.999)), lod).rgb;
}

float ign(vec2 p)
{
    return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec3 blurredDisp(vec2 pItem, vec2 disp, float disperse, float rad)
{
    float R   = max(rad, 0.5) * 1.5;                       // Gaussian reaches further than a flat disk
    float gap = R * sqrt(3.14159265 / float(TAPS));        // spacing between neighbouring taps, px
    float lod = clamp(log2(max(gap, 1.0)) + 0.35, 0.0, 6.0);
    float rot = ign(gl_FragCoord.xy) * 6.2831853;
    vec3  acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < TAPS; ++i) {
        float fi = float(i) + 0.5;
        float r  = sqrt(fi / float(TAPS));
        float a  = fi * GOLDEN + rot;
        float w  = exp(-2.2 * r * r);
        vec2  o  = vec2(cos(a), sin(a)) * r * R;
        vec3  c;
        c.r = backdropLod(pItem + o + disp * (1.0 + disperse), lod).r;
        c.g = backdropLod(pItem + o + disp,                    lod).g;
        c.b = backdropLod(pItem + o + disp * (1.0 - disperse), lod).b;
        acc  += c * w;
        wsum += w;
    }
    return acc / wsum;
}

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float roundBox(vec2 q, vec2 hs, float r)
{
    vec2 d = abs(q) - (hs - r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void main()
{
    vec2 p  = qt_TexCoord0 * itemSize;
    vec2 hs = glassSize * 0.5;
    vec2 q  = p - vec2(pad) - hs;
    float r = min(radius, min(hs.x, hs.y));

    float sd  = roundBox(q, hs, r);               // < 0 inside the glass
    float cov = clamp(0.5 - sd, 0.0, 1.0);        // anti-aliased coverage

    if (debug > 0.5) {
        vec4 s = texture(src, clamp((p + srcOffset) / srcSize, vec2(0.001), vec2(0.999)));
        fragColor = (s.a < 0.01 ? vec4(1.0, 0.0, 1.0, 1.0) : vec4(s.rgb / max(s.a, 1e-3), 1.0)) * cov * qt_Opacity;
        return;
    }

    // --- soft drop shadow (only visible outside the glass) ---
    float sds    = roundBox(q - vec2(0.0, 3.0), hs, r);
    float shadow = 0.30 * shadowAmt * (1.0 - smoothstep(-2.0, 9.0, sds));
    if (sd > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, shadow) * qt_Opacity;
        return;
    }

    // --- distance to edge + outward edge direction ---
    float t = max(-sd, 0.0);
    vec2 d2 = abs(q) - (hs - r);
    vec2 sg = vec2(q.x >= 0.0 ? 1.0 : -1.0, q.y >= 0.0 ? 1.0 : -1.0);
    vec2 m  = max(d2, 0.0);
    vec2 g  = (length(m) > 1e-4) ? normalize(m) * sg
                                 : ((d2.x > d2.y) ? vec2(sg.x, 0.0) : vec2(0.0, sg.y));

    // --- convex squircle bezel -> surface normal ---
    float bz   = max(bezel, 1.0) * 1.45;           // wider bezel: the glass reads thicker
    float u    = clamp(t / bz, 0.0, 1.0);
    float om   = 1.0 - u;
    float om4  = om * om * om * om;
    float slope = (om * om * om) / pow(max(1.0 - om4, 1e-3), 0.75);
    slope = min(slope, 7.0);
    vec3 n = normalize(vec3(g * slope, 1.0));

    // --- refraction: glass n≈1.5, ray enters straight down ---
    vec3 rd   = refract(vec3(0.0, 0.0, -1.0), n, 1.0 / 1.5);
    vec2 disp = rd.xy / max(-rd.z, 0.2) * thickness * 1.35;

    // the whole slab acts as a gentle vertical lens; blur is crisper right at the curved rim
    vec2 ps = vec2(p.x, (p.y - pad - hs.y) * (1.0 - magnify * 1.5) + pad + hs.y);
    float rad = blurPx * mix(0.45, 1.0, smoothstep(0.0, bz, t));

    vec3 col = blurredDisp(ps, disp, dispersion * 0.6, rad);

    // --- colour: vibrancy, then an ADAPTIVE tint (as the Dock: more tint where the backdrop would fight the text / icons) ---
    float l = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(l), col, saturation);
    float lw    = smoothstep(0.30, 0.80, l);
    float adapt = mix(0.78, 1.28, mix(1.0 - lw, lw, dark));
    vec3 tintC = mix(vec3(1.0), vec3(0.09, 0.09, 0.10), dark);
    // accent-tinted interface (accentTint.a = 1): the tint leans to a deep shade of the accent in dark mode (white text stays
    // readable on it) or a pale one in light mode, and a light wash of that shade covers the glass even when it is very clear
    // tinted glass: the refracted backdrop is coloured by the accent (multiplied, so its detail and the refraction stay visible)
    // and the flat tint is lighter, so the slab still reads as liquid glass rather than a flat accent card
    vec3 accTint = mix(mix(accentTint.rgb, vec3(1.0), 0.70), accentTint.rgb * 0.40, dark);
    tintC = mix(tintC, accTint, accentTint.a);
    col = mix(col, col * mix(accentTint.rgb, vec3(1.0), 0.35) * 1.25, accentTint.a);
    col = mix(col, tintC, clamp(tintMix * (1.0 - 0.45 * accentTint.a) * adapt, 0.0, 1.0));
    col = mix(col, accTint, accentTint.a * 0.08);
    // dark mode: a bright backdrop (a full moon, a white window) must not lift the tinted glass so far that white text sinks in
    float lt = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col *= mix(1.0, min(1.0, 0.42 / max(lt, 1e-3)), 0.85 * dark * accentTint.a);
    col += mix(0.055, 0.020, dark);

    // --- depth: soft light from above (clear glass, no darker inner edge: the same as the Dock) ---
    float ty = clamp((q.y + hs.y) / glassSize.y, 0.0, 1.0);
    col += (1.0 - ty) * mix(0.040, 0.034, dark);

    // --- edge light, measured from the real macOS Dock (the same as dockglass.frag) ---
    // a thin bright line along the top (+18%) and bottom (+30%) that fades out around the corners, only a whisper on the straight
    // sides (+2.5%), and a short glow just inside the top / bottom edge. All of it scales from the glass's own colour (the blurred
    // backdrop behind it), so the edge takes the colour of what is behind the glass. rim = 0.45 (the default Rim) is full strength.
    // (rimTint, ringW and flatInner are kept in the uniform block for older callers; the edge light replaces all three.)
    float rs    = clamp(rim / 0.45, 0.0, 3.0);
    float aY    = pow(abs(g.y), 1.5);                               // 0 on the sides, 1 on the top / bottom
    float wT    = smoothstep(-0.3, 0.3, -g.y);                      // 1 on the top, 0 on the bottom
    float lineA = 0.025 + aY * mix(0.275, 0.155, wT);
    float poolA = aY * mix(0.10, 0.055, wT);
    float kk    = (t - 0.7) / 0.55;
    float fE    = (lineA * exp(-(kk * kk)) + poolA * exp(-t / mix(3.0, 4.5, wT))) * rs;
    col = col * (1.0 + fE) + vec3(fE * 0.10);

    // fine triangular-distribution grain, same on every channel so it reads as texture, not colour noise
    float gn = hash12(gl_FragCoord.xy) + hash12(gl_FragCoord.xy * 1.7 + 17.0) - 1.0;
    col += gn * grain;

    col = clamp(col, 0.0, 1.0);

    float a = cov + shadow * (1.0 - cov);
    fragColor = vec4(col * cov, a) * qt_Opacity;   // premultiplied alpha
}
