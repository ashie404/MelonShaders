#version 450 compatibility

/* DRAWBUFFERS:01 */
layout (location = 0) out vec4 shadowcolor0Out;
layout (location = 1) out vec4 shadowcolor1Out;

// inputs from vertex shader

in vec2 texcoord;
in vec4 color;
in vec3 normal;

// uniforms

uniform sampler2D texture;

void main() {
	vec4 color = texture2D(texture, texcoord) * color;

	shadowcolor0Out = color;
	shadowcolor1Out = vec4(normal*0.5+0.5,1.0);
}