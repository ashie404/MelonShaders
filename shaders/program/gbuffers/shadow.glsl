/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 shadowcolorOut;

// Inputs from vertex shader

in vec2 texcoord;
in vec4 glcolor;
in float water;

// Uniforms

uniform sampler2D texture;

void main() {
	if (water > 0.5) {
		discard;
	} else {
		vec4 color = texture2D(texture, texcoord) * glcolor;
		shadowcolorOut = color;
	}
}


#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec4 glcolor;
out float water;

// Uniforms
attribute vec3 mc_Entity;

// Includes
#include "/lib/vertex/distortion.glsl"


void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

    if (mc_Entity.x == 8.0) {
		water = 1.0;
	} else {
		water = 0.0;
	}

    gl_Position = ftransform();
    gl_Position.xyz = distortShadow(gl_Position.xyz);
}

#endif