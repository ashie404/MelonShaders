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
layout (location = 0) out vec4 colorOut;

// Inputs from vertex shader
in vec2 texcoord;


// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex1;

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/fragment/shading.glsl"

void main() {
    FragInfo info = getFragInfo(texcoord);

    colorOut = info.albedo;
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