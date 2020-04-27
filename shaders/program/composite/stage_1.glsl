/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:04 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 bloomTileOut;

/*
const bool colortex4MipmapEnabled = true;
*/

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/post/bloomTiles.glsl"

void main() {
    vec4 color = texture2D(colortex0, texcoord);

    #ifdef BLOOM
    // calculate all bloom tiles
    vec3 bloomTiles = vec3(0.0);
    bloomTiles += calcBloomTile(vec2(0.0,0.0), 2.0);
    bloomTiles += calcBloomTile(vec2(0.25,0.0), 3.0);
    bloomTiles += calcBloomTile(vec2(0.25,0.25), 4.0);
    bloomTiles += calcBloomTile(vec2(0.5,0.25), 5.0);
    bloomTiles += calcBloomTile(vec2(0.5,0.5), 6.0);
    bloomTileOut = vec4(bloomTiles,1.0);
    #endif

    colorOut = color;
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;

uniform float sunAngle;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif