#version 440
// Feathered left and right edges (scrolling text): content fades out smoothly instead of being cut off.
// Build:  /usr/lib/qt6/bin/qsb --qt6 -o hfade.frag.qsb hfade.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float fadeLeft;    // fraction of the width that fades in at the left
    float fadeRight;   // fraction of the width that fades out at the right
};
layout(binding = 1) uniform sampler2D source;
void main()
{
    float x = qt_TexCoord0.x;
    float a = smoothstep(0.0, max(fadeLeft, 1e-4), x) * smoothstep(0.0, max(fadeRight, 1e-4), 1.0 - x);
    fragColor = texture(source, qt_TexCoord0) * (a * qt_Opacity);
}
