/* 
    Melon Shaders by June
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colorOut;

/*
const bool colortex4MipmapEnabled = true;
*/

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex6;

uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/post/bloomTiles.glsl"

void main() {
    vec4 color = texture2D(colortex0, texcoord);

    #ifdef BLOOM
    // get all bloom tiles and calculate them with final color
    vec3 bloom = vec3(0.0);
    bloom += getBloomTile(vec2(0.0,0.0), 2.0, texcoord);
    bloom += getBloomTile(vec2(0.3,0.0), 3.0, texcoord);
    bloom += getBloomTile(vec2(0.3,0.3), 4.0, texcoord);
    bloom += getBloomTile(vec2(0.6,0.3), 5.0, texcoord);
    bloom += getBloomTile(vec2(0.6,0.6), 6.0, texcoord);
    bloom /= 5.0;
    color.rgb = mix(color.rgb, bloom, clamp01(BLOOM_STRENGTH));
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