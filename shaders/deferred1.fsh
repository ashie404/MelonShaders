#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// deferred pass 1: reflections on solid terrain

/* DRAWBUFFERS:0352 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex3Out;
layout (location = 2) out vec4 colortex5Out;
layout (location = 3) out vec4 colortex2Out;

// inputs from vertex shader

in float isNight;
in vec3 lightVector;
in vec3 lightColor;
in vec3 skyColor;
in vec3 normal;
in vec4 texcoord;
in vec4 position;

// uniforms

uniform int isEyeInWater;
uniform int worldTime;

uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float near;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D gaux2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/shadow.glsl"
#include "/lib/distort.glsl"

void main() {
    float z = texture2D(depthtex0, texcoord.st).r;
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    
    vec3 finalColor = texture2D(colortex0, texcoord.st).rgb;

    vec4 screenPos = vec4(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r) * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;

    vec4 worldPos = gbufferModelViewInverse * viewPos;

    #ifdef SPECULAR
    #ifdef SCREENSPACE_REFLECTIONS
    #ifdef SPECULAR_REFLECTIONS
    PBRData pbrData = getPBRData(texture2D(colortex3, texcoord.st));
    float roughness = pow(1 - pbrData.smoothness, 2);
    // get pbr data and calculate SSR if enabled
    if (roughness < 0.25) {
        if (z != 1) {
            // bayer64 dither
            float dither = bayer64(gl_FragCoord.xy);
            // calculate ssr color
            vec4 reflection = roughReflection(viewPos.xyz, frag.normal, dither, colortex5, pbrData.smoothness);
            //reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
            //reflection.rgb /= 16;
            finalColor *= mix(vec3(1), reflection.rgb, reflection.a-roughness);
        }
    }
    #endif
    #endif
    #endif

    // output

    colortex0Out = vec4(finalColor, 1);
    colortex3Out = texture2D(colortex3, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
    
    #ifdef SCREENSPACE_REFLECTIONS
	colortex5Out = vec4(pow(finalColor, vec3(0.125)) * 0.5, float(z < 1.0)); //gaux2
    #endif
}