#version 450 compatibility

// outputs to fragment shader

out vec2 texcoord;
out vec4 color;

// uniforms
attribute vec4 mc_Entity;

// includes

#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);
}