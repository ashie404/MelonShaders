/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 3 */
out vec4 dataOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec3 normal;
in vec4 glcolor;

// Uniforms
uniform mat4 gbufferModelViewInverse;
uniform sampler2D texture;
uniform sampler2D colortex1;
uniform sampler2D colortex4;

void main() {
    // output everything
    dataOut = vec4(
        1.0,
        0.0,
        0.0,
        0.0
    );
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec3 normal;
out vec4 glcolor;

// Uniforms
uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

// Includes
#include "/lib/util/taaJitter.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    glcolor = gl_Color;

    gl_Position = ftransform();

    #ifdef TAA
    gl_Position.xy += jitter(2.0)*gl_Position.w;
    #endif
}

#endif