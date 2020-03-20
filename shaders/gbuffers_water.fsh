#version 120

#include "lib/framebuffer.glsl"

uniform sampler2D texture;

uniform float worldTime;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

varying float isWater;

void main() {
    vec3 blockColor = getAlbedo(texcoord.st);
    blockColor.rgb *= tintColor;

    if (isWater == 1)
    {
        GCOLOR_OUT = vec4(0.12,0.22,0.72,0.65);
        GDEPTH_OUT = vec4(lmcoord.st / 16,0,0);
        GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else {
        GCOLOR_OUT = vec4(blockColor, 1.0);
        GDEPTH_OUT = vec4(lmcoord.st / 16,0,0);
        GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
    }
    
}