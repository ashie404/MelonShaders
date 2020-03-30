#version 450 compatibility

// outputs to fragment shader

out vec4 texcoord;
out vec3 lightVector;
out vec3 lightColor;
out vec3 skyColor;
out float isNight;
out vec3 normal;

// uniforms

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

// includes

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

void main() {

    dayNightCalc(isNight, lightVector, lightColor, skyColor);
	gl_Position = ftransform();
    normal = normalize(gl_NormalMatrix * gl_Normal);
    texcoord = gl_MultiTexCoord0;
}