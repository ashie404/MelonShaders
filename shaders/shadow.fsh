#version 450 compatibility

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colortex0Out;

// inputs from vertex shader

in vec2 texcoord;
in vec4 color;

// uniforms

uniform sampler2D texture;

void main() {
	vec4 color = texture2D(texture, texcoord) * color;

	colortex0Out = color;
}