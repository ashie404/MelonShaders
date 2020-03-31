#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// composite pass 3: final composite of bloom and main image

/* DRAWBUFFERS:012 */
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
#include "/lib/framebuffer.glsl"
#include "/lib/util.glsl"
#include "/lib/bloom.glsl"

void main() {

    #ifdef BLOOM
    vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);

    vec3 bloom = vec3(0.0);
    bloom += getBloomTile(2.0, texcoord.st, vec2(0.0                     ,                    0.0));
    bloom += getBloomTile(3.0, texcoord.st, vec2(0.0                     , 0.25   + pixel.y * 2.0));
    bloom += getBloomTile(4.0, texcoord.st, vec2(0.125    + pixel.x * 2.0, 0.25   + pixel.y * 2.0));
    bloom += getBloomTile(5.0, texcoord.st, vec2(0.1875   + pixel.x * 4.0, 0.25   + pixel.y * 2.0));
    bloom += getBloomTile(6.0, texcoord.st, vec2(0.125    + pixel.x * 2.0, 0.3125 + pixel.y * 4.0));
    bloom += getBloomTile(7.0, texcoord.st, vec2(0.140625 + pixel.x * 4.0, 0.3125 + pixel.y * 4.0));
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    // output

    #ifndef BLOOM
    colortex0Out = color;
    #else
    colortex0Out = mix(color, vec4(bloom,1), BLOOM_STRENGTH);
    #endif
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
}