#version 120

varying vec4 texcoord;

varying float nightDesaturation;

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

void main() {
    desaturateNight(nightDesaturation);
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}