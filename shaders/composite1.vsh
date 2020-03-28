#version 450 compatibility

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

out vec4 texcoord;

out vec3 lightVector;
out vec3 lightColor;
out vec3 skyColor;
out float isNight;
out vec3 normal;

out vec4 position;
uniform mat4 gbufferModelViewInverse;

attribute vec4 mc_Entity;

out float isTransparent;

#define VSH
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

float getIsTransparent(in float materialId) {
    if (materialId == 160.0) { // stained glass pane
        return 1.0;
    }
    if (materialId == 95.0) { //stained glass
        return 1.0;
    }
    if (materialId == 79.0) { //ice
        return 1.0;
    }
    if (materialId == 8.0 || materialId == 9.0) { //water 
        return 1.0;
    }
    return 0.0;
}

void main() {

    dayNightCalc(isNight, lightVector, lightColor, skyColor);

    normal = normalize(gl_NormalMatrix * gl_Normal);
    position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    isTransparent = getIsTransparent(mc_Entity.x);
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}