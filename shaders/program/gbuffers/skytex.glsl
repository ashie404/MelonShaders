/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0,2 */
out vec4 colorOut;
out vec3 skyOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;
uniform mat4 gbufferModelViewInverse;

void main() {
    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    albedo.rgb = toLinear(albedo.rgb);
    
    #ifdef BASIC
    albedo.rgb *= SKYCLR_BRIGHT;
    #else
    albedo.rgb *= SKYBOX_BRIGHT;
    #endif

    // output everything
    colorOut = vec4(albedo.rgb, 1.0);
	skyOut = albedo.rgb;
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    glcolor = gl_Color;

    gl_Position = ftransform();
}

#endif