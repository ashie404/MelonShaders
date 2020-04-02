#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// composite pass 3: final bloom mix with composite

/* DRAWBUFFERS:0124 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;

// inputs from vertex shader

in vec4 texcoord;

// uniforms

uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex3;

// constants

const bool colortex4MipmapEnabled = true;

// includes

#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/bloom.glsl"

void main() {

    vec4 color = texture2D(colortex0, texcoord.st);

    // get all bloom tiles and combine with final color
    #ifdef BLOOM
    vec3 finalBloom = vec3(0.0);
    finalBloom += getBloomTile(vec2(0,0), 2.0, texcoord.st);
    finalBloom += getBloomTile(vec2(0.25,0), 3.0, texcoord.st);
    finalBloom += getBloomTile(vec2(0.25,0.25), 4.0, texcoord.st);
    finalBloom += getBloomTile(vec2(0.5,0.25), 5.0, texcoord.st);
    finalBloom += getBloomTile(vec2(0.5,0.5), 6.0, texcoord.st);
    color = mix(color, vec4(finalBloom,1), BLOOM_STRENGTH);
    #endif

    // output

    colortex0Out = color;
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
}