#version 450 compatibility

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colortex0Out;

uniform sampler2D lightmap;
uniform sampler2D texture;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 color;

void main() {
	vec4 color = texture2D(texture, texcoord) * color;

	colortex0Out = color;
}