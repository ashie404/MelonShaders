/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 shadowcolor0Out;

// inputs from vertex shader

in vec2 texcoord;
in vec4 color;

// uniforms

uniform sampler2D texture;

void main() {
	vec4 color = texture2D(texture, texcoord) * color;

	shadowcolor0Out = color;
}

#endif

// VERTEX SHADER //

#ifdef VERT

// outputs to fragment shader

out vec2 texcoord;
out vec4 color;

// uniforms
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelViewInverse;

// includes

#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);
}

#endif