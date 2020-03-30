#version 450 compatibility

// outputs to fragment shader

out float isNight;
out vec3 lightVector;
out vec3 lightColor;
out vec3 skyColor;
out vec3 normal;
out vec4 position;
out vec4 texcoord;

// uniforms

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferModelViewInverse;

// includes

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

void main() {
    dayNightCalc(isNight, lightVector, lightColor, skyColor);

    normal = normalize(gl_NormalMatrix * gl_Normal);
    position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}