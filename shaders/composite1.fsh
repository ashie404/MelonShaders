#version 120

#extension GL_ARB_shader_texture_lod : enable

// composite pass 1: reflections & translucent lighting

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
uniform int worldTime;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform vec3 shadowLightPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;

uniform sampler2D gdepthtex;
uniform sampler2D gaux2;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D specular;
uniform sampler2D shadowcolor0;
uniform sampler2D normals;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform vec3 upPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;

varying float isTransparent;
varying vec3 normal;

varying vec4 position;
uniform int isEyeInWater;

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

    vec4 finalColor = texture2D(gcolor, texcoord.st);
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
        if (isNight == 1) {
            skyReflection += DrawStars(normalize(reflectionPosWS));
        }
        skyReflection /= 1.45;

        #ifdef SCREENSPACE_REFLECTIONS
        // bayer64 dither
        float dither = bayer64(gl_FragCoord.xy);
        // calculate ssr color
        vec4 reflection = reflection(viewPos,normal,dither, gaux2);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
        // snells window refraction indexes
        vec3 n1 = isEyeInWater > 0 ? vec3(1.333) : vec3(1.00029);
        vec3 n2 = isEyeInWater > 0 ? vec3(1.00029) : vec3(1.333);
        // eye is in water, calculate snell's window and use generic underwater color for reflections
        if (isEyeInWater == 1) {
            vec3 rayDir = refract(normalize(viewPos), normal, n1.r/n2.r); // calculate snell's window
            if (rayDir == vec3(0))
            {
                // mix generic underwater color and ssr based on ssr alpha
                finalColor = vec4(mix(vec3(0.01, 0.02, 0.05), reflection.rgb, reflection.a), 1);
            }  
            else {
                // use sky as water color, but make it more transparent. (mix for translucency)
                finalColor = mix(finalColor, vec4(skyReflection, 0.5), 0.5);
            }
        }
        // eye isn't in water, use sky for reflections and no snell's window
        else {
            // calculate reflections
            if (closenessOfSunToWater < 0.998) {
                // mix sky reflection and ssr based on ssr alpha
                finalColor = mix(finalColor, vec4(mix(skyReflection, reflection.rgb, reflection.a), 0.85), 0.65);
            } else {
                // sun reflection
                if (reflection.a < 0.1) {
                    finalColor = vec4(0.95,0.95,0.9, 0.7);
                }
            }
        }
        // if ssr is non-applicable
        #else
        // calculate basic color
        if (closenessOfSunToWater < 0.998) {
            // basic sky reflection color
            finalColor = mix(finalColor, vec4(skyReflection, 1), 0.65);
        }
        else {
            // basic sun reflection
            finalColor = mix(finalColor, vec4(0.95,0.95,0.9,1), 0.7);
        }
        #endif
    }

    #ifdef BLOOM
    vec4 bloomSample = vec4(0);

    if (isNight == 0) {
        if (luma(finalColor.rgb) > 0.75) {
            bloomSample = finalColor;
        }
    } else {
        if (luma(finalColor.rgb) > 0.5) {
            bloomSample = finalColor;
        }
    }
    #endif

    // output
    /* DRAWBUFFERS:01234 */
    gl_FragData[0] = finalColor;
    gl_FragData[1] = texture2D(gdepth, texcoord.st);
    gl_FragData[2] = texture2D(gnormal, texcoord.st);
    gl_FragData[3] = texture2D(colortex3, texcoord.st);
    #ifdef BLOOM
    gl_FragData[4] = bloomSample;
    #endif
}