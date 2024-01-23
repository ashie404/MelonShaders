/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0 */
out vec4 albedoOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec3 normal;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;

// Includes

void main() {
    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    // if alpha is below a reasonable threshold discard entire fragment
    if (albedo.a < 0.05) {
        discard;
    }

    // output everything
	albedoOut = albedo;
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec3 normal;
out vec4 glcolor;

// Uniforms

// Includes

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    glcolor = gl_Color;

    gl_Position = ftransform();
}

#endif