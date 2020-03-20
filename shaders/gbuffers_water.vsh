#version 120

#include "lib/waving.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

attribute vec4 mc_Entity;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;

varying float isWater;
varying float isIce;
varying float isNight;
varying float isTransparent;

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

void main()
{
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
    if (mc_Entity.x == 8 || mc_Entity.x == 9) {
        isIce = 0;
        isWater = 1;
        position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        //position.xyz += WavingWater(position.xyz);
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    else if (mc_Entity.x == 79.0) {
        isIce = 1;
        isWater = 0;
    }
    else {
        isIce = 0;
        isWater = 0;
    }
    if (worldTime < 12700 || worldTime > 23250) {
        isNight = 1;
    } 
    else {
        isNight = 0;
    }
    isTransparent = getIsTransparent(mc_Entity.x);
}