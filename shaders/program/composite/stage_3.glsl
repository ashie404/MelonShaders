/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

const bool colortex2MipmapEnabled = true;

/* RENDERTARGETS: 0,2 */
out vec3 colorOut;
out vec3 bloomTileOut;

// Inputs from vertex shader
in vec2 texcoord;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex2;

uniform float viewWidth;
uniform float viewHeight;

// Includes
#include "/lib/post/bloom.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    #ifdef BLOOM
    // calculate all bloom tiles
    vec3 bloomTiles = vec3(0.0);
    bloomTiles += calcBloomTile(vec2(0.0,0.0), 2.0);
    bloomTiles += calcBloomTile(vec2(0.3,0.0), 3.0);
    bloomTiles += calcBloomTile(vec2(0.3,0.3), 4.0);
    bloomTiles += calcBloomTile(vec2(0.6,0.3), 5.0);
    bloomTiles += calcBloomTile(vec2(0.6,0.6), 6.0);
    bloomTileOut = bloomTiles;
    #endif

    colorOut = color;
}

#endif

// VERTEX SHADER //

#ifdef VSH

out vec2 texcoord;

uniform float sunAngle;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif