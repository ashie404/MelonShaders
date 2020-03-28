#version 450 compatibility

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colortex0Out;

#include "/lib/settings.glsl"

void main() {
    colortex0Out = vec4(NIGHT_SKY_COLOR,1);
}