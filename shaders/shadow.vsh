#version 120

attribute vec4 mc_Entity;

varying vec2 texcoord;
varying vec4 color;

#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);
}