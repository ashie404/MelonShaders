#version 120

#include "/lib/settings.glsl"

void main() {
    gl_FragData[0] = vec4(NIGHT_SKY_COLOR,1);
}