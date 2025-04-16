shader_type canvas_item;

uniform int hue_shift: hint_range(-360, 360, 1) = 0; // range: 0 to 360

// Converts RGB to HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0., -1./3., 2./3., -1.);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x);
}

// Converts HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0., 1./3., 2./3.)) * 6. - 3.);
    return c.z * mix(vec3(1.), clamp(p - 1., 0., 1.), c.y);
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    vec3 hsv = rgb2hsv(texture_color.rgb);
    hsv.x = mod(hsv.x + float(hue_shift)/360.0, 1.0);
    vec3 rgb_shifted = hsv2rgb(hsv);
    COLOR = vec4(rgb_shifted, texture_color.a);
}
