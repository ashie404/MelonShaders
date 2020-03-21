#version 120

attribute vec4 mc_Entity;

varying vec2 texcoord;
varying vec4 color;
varying float isTransparent;


#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

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
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;

	isTransparent = getIsTransparent(mc_Entity.x);

	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);

}