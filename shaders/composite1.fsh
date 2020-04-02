#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

// composite pass 1: reflections & translucent lighting

/* DRAWBUFFERS:01234 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex3Out;
layout (location = 4) out vec4 colortex4Out;

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
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float far;
uniform float near;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D gaux2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

// includes

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/distort.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/shadow.glsl"
#include "/lib/sky.glsl"

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {

    vec4 finalColor = texture2D(colortex0, texcoord.st);
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);
    vec4 newPosition = position;
    newPosition /= position.w;

    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = toNDC(screenPos);

    // 0.1 emission marks translucent lighting
    if (frag.emission == 0.1) {
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
        }
        else {
            fShadowPos = vec4(shadowPos, 0);
        }

        PBRData pbrData = getPBRData(texture2D(colortex3, texcoord.st));

        finalColor = vec4(calculateLighting(frag, lightmap, fShadowPos, normalize(viewPos.xyz), pbrData), 1);
    }
    // 0.5 emission marks water, calculate reflectins
    else if (frag.emission == 0.5) {

        // calculate water fog
        float linearDepth = (2.0 * near) / (far + near - texture2D(depthtex0, texcoord.st).r * (far - near));
        float linearDepth1 = (2.0 * near) / (far + near - texture2D(depthtex1, texcoord.st).r * (far - near));
        float depth = clamp01((linearDepth-linearDepth1)*24);
        finalColor = mix(finalColor, vec4(0,0.01,0.05,1), depth);

        // calculate water reflections
        // calculate reflections
        // calculate screen space reflections
        vec3 normal = getNormal(texcoord.st);
        vec3 sunPosWorld = mat3(gbufferModelViewInverse) * sunPosition;
        vec3 normalWorld = mat3(gbufferModelViewInverse) * normal;
        vec3 sunReflection = reflect(normalize(position.xyz), normalize(normalWorld));
        float closenessOfSunToWater = dot(normalize(sunReflection), normalize(sunPosWorld));

        // calculate sky reflection
        vec3 reflectionPos = reflect(normalize(viewPos.xyz), normal);
        vec3 reflectionPosWS = mat3(gbufferModelViewInverse) * reflectionPos;
        vec3 skyReflection = GetSkyColor(normalize(reflectionPosWS), normalize(sunPosWorld), isNight);
        if (isNight > 0.9) {
            skyReflection += DrawStars(normalize(reflectionPosWS));
        }
        skyReflection /= 1.45;

        #ifdef SCREENSPACE_REFLECTIONS
        // bayer64 dither
        float dither = bayer64(gl_FragCoord.xy);
        // calculate ssr color
        vec4 reflection = reflection(viewPos,normal,dither,gaux2);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
        // snells window refraction indexes
        vec3 n1 = isEyeInWater > 0 ? vec3(1.333) : vec3(1.00029);
        vec3 n2 = isEyeInWater > 0 ? vec3(1.00029) : vec3(1.333);
        // eye is in water, calculate snell's window and use generic underwater color for reflections
        if (isEyeInWater > 0) {
            vec3 rayDir = refract(normalize(viewPos), normal, n1.r/n2.r); // calculate snell's window
            if (rayDir == vec3(0))
            {
                // mix generic underwater color and ssr based on ssr alpha
                finalColor = vec4(mix(vec3(0.01, 0.02, 0.05), reflection.rgb, reflection.a), 1);
            }
        }
        // eye isn't in water, use sky for reflections and no snell's window
        else {
            // calculate water color
            vec4 waterColor = vec4(0.25, 0.64, 0.87,1);
            waterColor.rgb*=(1.0-isNight);
            vec4 reflectionColor = vec4(mix(skyReflection, reflection.rgb, reflection.a),1);
            waterColor = mix(waterColor, reflectionColor, 0.4);
            // calculate reflections
            // mix water color and underwater
            finalColor = mix(finalColor, waterColor, 0.075);
        }
        // if ssr is disabled
        #else

        // calculate basic color
        vec4 waterColor = vec4(0.25, 0.64, 0.87,1);
        waterColor.rgb*=(1.0-isNight);
        waterColor = mix(waterColor, vec4(skyReflection, 1), 0.4);
        finalColor = mix(finalColor, waterColor, 0.075);

        #endif
    }

    #ifdef BLOOM
    vec4 bloomSample = vec4(0);
    if (luma(finalColor.rgb) > 7.5) {
        // move final color back into SDR if in HDR (only emissives should be in hdr, so check that value) 
        if (frag.emission >= 0.99) {
            finalColor /= 7.5;
        }
        bloomSample = finalColor;
    }
    #endif

    #ifdef FOG
    // calculate fog
    float depth = texture2D(depthtex0, texcoord.st);
    float ldepth = (2.0 * near) / (far + near - depth * (far - near));

    #endif

    // output
    
    colortex0Out = finalColor;
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
    colortex3Out = texture2D(colortex3, texcoord.st);
    #ifdef BLOOM
    colortex4Out = bloomSample;
    #endif
}