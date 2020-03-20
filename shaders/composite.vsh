#version 120

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
varying vec3 normal;

attribute vec4 mc_Entity;

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

    normal = normalize(gl_NormalMatrix * gl_Normal);
    
    isTransparent = getIsTransparent(mc_Entity.x);
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}