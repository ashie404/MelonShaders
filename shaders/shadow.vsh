#version 120

attribute vec4 mc_Entity;

varying vec4 texcoord;
varying vec4 color;
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
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    color = gl_Color;

    isTransparent = getIsTransparent(mc_Entity.x);
}