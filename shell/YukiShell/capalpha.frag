// capalpha — a window picture from Hyprland (drawn over opaque black, so it is the window's colour already multiplied by its alpha)
// shown with the transparency it really has on screen: kitty's see-through background, Dolphin's faded window.
// Output is premultiplied: rgb + behind * (1 - alpha), i.e. exactly the window composited over what is behind it.
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;   // Hyprland's whole-window opacity (the item's opacity)
    float bgAlpha;      // the window's own background alpha (kitty background_opacity); 1 = opaque
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec4 c = texture(source, qt_TexCoord0);
    fragColor = vec4(c.rgb, bgAlpha * c.a) * qt_Opacity;
}
