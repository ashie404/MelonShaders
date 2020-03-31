#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// composite pass 2: lens flare & bloom tile calculation

/* DRAWBUFFERS:0124 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex4Out;

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

    #ifdef LENS_FLARE
    vec2 tex_offset = 1.0 / vec2(viewWidth, viewHeight); // gets size of single texel
    vec3 result = texture2D(colortex4, texcoord.st).rgb; // current fragment's contribution
    // lens flare pass
    for(int i = 1; i <= 16; ++i)
    {
        float weight = 2.546479089 / (i * i + 10.185916358); //simplified version of: 0.25 / ((i*i*PI/32) + 1);
        result += texture2D(colortex4, texcoord.st + vec2(tex_offset.x * i, tex_offset.y * i)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(tex_offset.x * i, tex_offset.y * i)).rgb * weight;
        result += texture2D(colortex4, texcoord.st + vec2(tex_offset.x * i * 1.5, tex_offset.y * i * 1.5)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(tex_offset.x * i * 1.5, tex_offset.y * i * 1.5)).rgb * weight;
        result += texture2D(colortex4, texcoord.st + vec2(tex_offset.x * i * 2, tex_offset.y * i * 2)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(tex_offset.x * i * 2, tex_offset.y * i * 2)).rgb * weight;
        result += texture2D(colortex4, texcoord.st + vec2(-tex_offset.x * i, tex_offset.y * i)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(-tex_offset.x * i, tex_offset.y * i)).rgb * weight;
        result += texture2D(colortex4, texcoord.st + vec2(-tex_offset.x * i * 1.5, tex_offset.y * i * 1.5)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(-tex_offset.x * i * 1.5, tex_offset.y * i * 1.5)).rgb * weight;
        result += texture2D(colortex4, texcoord.st + vec2(-tex_offset.x * i * 2, tex_offset.y * i * 2)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(-tex_offset.x * i * 2, tex_offset.y * i * 2)).rgb * weight;
    }
    result /= 8;
    color += vec4(result, 1);
    #endif

    #ifdef BLOOM
    // calculate all bloom tiles
    vec3 bloomTiles = vec3(0.0);
    bloomTiles += calcBloomTile(vec2(0,0), 2.0);
    bloomTiles += calcBloomTile(vec2(0.25,0), 3.0);
    bloomTiles += calcBloomTile(vec2(0.25,0.25), 4.0);
    bloomTiles += calcBloomTile(vec2(0.5,0.25), 5.0);
    bloomTiles += calcBloomTile(vec2(0.5,0.5), 6.0);
    colortex4Out = vec4(bloomTiles,1);
    #endif

    // output

    colortex0Out = color;
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
}