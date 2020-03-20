#version 120

#include "lib/framebuffer.glsl"

uniform sampler2D texture;

uniform int worldTime;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    GCOLOR_OUT = blockColor;
    GDEPTH_OUT = vec4(lmcoord.st / 16,0,0);
    GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
}