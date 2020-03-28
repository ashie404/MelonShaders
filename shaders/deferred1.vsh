#version 450 compatibility

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

out vec4 texcoord;

out vec3 lightVector;
out vec3 lightColor;
out vec3 skyColor;
out float isNight;
out vec3 normal;

attribute vec4 mc_Entity;

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

void main() {

    dayNightCalc(isNight, lightVector, lightColor, skyColor);

	gl_Position = ftransform();

    normal = gl_Normal;


    texcoord = gl_MultiTexCoord0;
}