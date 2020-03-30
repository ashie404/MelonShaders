#version 450 compatibility

// outputs to fragment shader

out vec4 texcoord;
out float nightDesaturation;

// uniforms

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

// includes

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

void main() {
    desaturateNight(nightDesaturation);
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}