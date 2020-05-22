/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:06 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 taaOut;

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
uniform int frameCounter;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

#include "/lib/post/bloomTiles.glsl"
#include "/lib/temporalUtil.glsl"

void main() {
    #ifdef TAA
    vec4 color = texture2D(colortex0, texcoord)+(texture2D(colortex6, texcoord)-texture2D(colortex0, texcoord));
    #else
    vec4 color = texture2D(colortex0, texcoord);
    #endif

    #ifdef BLOOM
    // get all bloom tiles and calculate them with final color
    vec3 bloom = vec3(0.0);
    bloom += getBloomTile(vec2(0.0,0.0), 2.0, texcoord);
    bloom += getBloomTile(vec2(0.3,0.0), 3.0, texcoord);
    bloom += getBloomTile(vec2(0.3,0.3), 4.0, texcoord);
    bloom += getBloomTile(vec2(0.6,0.3), 5.0, texcoord);
    bloom += getBloomTile(vec2(0.6,0.6), 6.0, texcoord);
    color = mix(color, vec4(bloom, 1.0), BLOOM_STRENGTH-0.75);
    #endif

    colorOut = color;
    #ifdef TAA
    vec2 reprojectedCoord = reprojectCoords(vec3(texcoord, texture2D(depthtex0, texcoord)));
    taaOut = vec4((texture2D(colortex0, texcoord+jitter()).rgb/1.5)+(texture2D(colortex6, reprojectedCoord).rgb/1.5), 1.0);
    #endif
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