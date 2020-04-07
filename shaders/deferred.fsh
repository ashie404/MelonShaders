#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// deferred pass 0: lighting

/*
const bool colortex6Clear = false;
*/

/* DRAWBUFFERS:03526 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex3Out;
layout (location = 2) out vec4 colortex5Out;
layout (location = 3) out vec4 colortex2Out;
layout (location = 4) out vec4 giOut;

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

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

uniform mat4 gbufferProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D colortex6;
uniform sampler2D gaux2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

// includes

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/distort.glsl"
#include "/lib/shadow.glsl"
#include "/lib/sky.glsl"

void main() {
    float z = texture2D(depthtex0, texcoord.st).r;
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);

    // calculate distorted shadow coordinate
    vec4 pos = vec4(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r) * 2.0 - 1.0, 1.0);
    pos = gbufferProjectionInverse * pos;
    pos = gbufferModelViewInverse * pos;
    pos = shadowModelView * pos;
    pos = shadowProjection * pos;
    pos /= pos.w;
    vec3 shadowPos = distort(pos.xyz) * 0.5 + 0.5;

    float lightDot = dot(normalize(shadowLightPosition), normal);
    vec4 fShadowPos = vec4(shadowPos, 0);
    if (lightDot > 0.0) {
        fShadowPos = vec4(shadowPos, 1.0);
    } else {
        fShadowPos = vec4(shadowPos, 0);
    }

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;

    PBRData pbrData = getPBRData(texture2D(colortex3, texcoord.st));

    vec3 finalColor = vec3(0);

    // if sky
    if (texture2D(depthtex0, texcoord.st).r == 1) {
        // render sky
	    finalColor = GetSkyColor(worldPos, mat3(gbufferModelViewInverse) * sunPosition, isNight);
        // draw stars based on night transition value
        finalColor += mix(vec3(0), DrawStars(normalize(worldPos)), isNight);
    } else {
        // if is not hand calculate lighting
        if (frag.emission != 0.7) {
            finalColor = calculateLighting(frag, lightmap, fShadowPos, pos.xyz, screenPos.xyz, normalize(viewPos.xyz), pbrData);
        } else {
            finalColor = texture2D(colortex0, texcoord.st).rgb;
        }
    }

    // output

    colortex0Out = vec4(finalColor, 1);
    colortex3Out = texture2D(colortex3, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);

    #ifdef SCREENSPACE_REFLECTIONS
	colortex5Out = vec4(pow(finalColor, vec3(0.125)) * 0.5, float(z < 1.0)); //gaux2
    #endif

    #ifdef GI
    giOut = vec4(texture2D(colortex6, frag.coord).rgb + getGI(fShadowPos.xyz, pos.xyz, viewPos.xyz, screenPos.xyz, frag, texture2D(shadowtex0, fShadowPos.xy).r) - texture2D(colortex6, frag.coord).rgb/2,1);
    #endif
}