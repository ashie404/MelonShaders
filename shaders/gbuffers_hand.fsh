#version 120

#include "lib/framebuffer.glsl"

uniform sampler2D texture;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

void main() {
    vec4 handColor = texture2D(texture, texcoord.st);
    handColor.rgb *= tintColor;

    GCOLOR_OUT = handColor;
    GDEPTH_OUT = vec4(lmcoord.st / 16, 0, 1);
    GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
}