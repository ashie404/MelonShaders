#version 450 compatibility

/* DRAWBUFFERS:01 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;

#include "/lib/settings.glsl"

void main() {
    colortex0Out = vec4(NIGHT_SKY_COLOR,1);
    colortex1Out = vec4(0,0,0,0);
}