/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#define ACES
#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

#define MELONINFO 0 // Melon Shaders by Ashie. V3.0. [0 1]

/* RENDERTARGETS: 0 */
out vec4 screenOut;

// Inputs from vertex shader
in vec2 texcoord;

// Uniforms
uniform sampler2D colortex0;

// Includes

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    screenOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;

// Uniforms

// Includes

void main() {
    gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif