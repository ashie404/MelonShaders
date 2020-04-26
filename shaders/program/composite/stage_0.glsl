/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colorOut;

in vec2 texcoord;

uniform sampler2D colortex0;

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    colorOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif