#version 120

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
varying vec3 normal;

attribute vec4 mc_Entity;

#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

void main() {
    if (worldTime < 12700 || worldTime > 23250) {
        lightVector = normalize(sunPosition);
        lightColor = vec3(1.0);
        skyColor = vec3(0.012, 0.015, 0.03);
        isNight = 0;
    } 
    else {
        lightVector = normalize(moonPosition);
        lightColor = vec3(0.1);
        skyColor = vec3(0.0012, 0.0015, 0.003);
        isNight = 1;
    }

	gl_Position = ftransform();

    normal = normalize(gl_NormalMatrix * gl_Normal);

    texcoord = gl_MultiTexCoord0;
}