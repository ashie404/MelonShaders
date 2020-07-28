/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/*
const bool colortex0MipmapEnabled = true;
const bool colortex2MipmapEnabled = true;
*/

/* DRAWBUFFERS:0 */
layout (location = 0) out vec3 colorOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec4 times;
in vec3 lightColor;
in vec3 ambientColor;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;

uniform sampler2D depthtex0;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;

uniform vec3 fogColor;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;

uniform float eyeAltitude;

uniform int isEyeInWater;

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/fragment/reflection.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/atmosphere.glsl"

void main() {
    float depth0 = texture2D(depthtex0, texcoord).r;

    FragInfo info = getFragInfo(texcoord);

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    vec3 color = info.albedo.rgb;

    #ifdef REFLECTIONS
    if (depth0 != 1.0) {
        float roughness = pow(1.0 - info.specular.r, 2.0);
        if (info.matMask == 3) {
            #ifdef SSR
            vec4 reflectionColor = reflection(viewPos.xyz, info.normal, fract(frameTimeCounter * 4.0 + interleavedGradientNoise(gl_FragCoord.xy)), colortex0);
            #else
            vec4 reflectionColor = vec4(0.0);
            #endif
            vec3 skyReflectionColor = vec3(0.0);
            if (reflectionColor.a < 0.5 && isEyeInWater == 0) {
                #if WORLD == 0

                skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal));
                calculateCelestialBodies(reflect(viewPos.xyz, info.normal), reflect(worldPos.xyz, mat3(gbufferModelViewInverse)*info.normal), skyReflectionColor);
                if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                    skyReflectionColor *= clamp01((eyeBrightnessSmooth.y-9)/55.0);
                } else if (eyeBrightnessSmooth.y <= 8) {
                    skyReflectionColor *= 0.0;
                }

                #endif
            }
            float fresnel = fresnel_schlick(viewPos.xyz, info.normal, 0.02);
            color += mix(vec3(0.0), mix(vec3(0.0), reflectionColor.rgb, reflectionColor.a)+skyReflectionColor, fresnel);
        }
        #ifdef SPEC_REFLECTIONS
        else if (roughness <= 0.15) {
            #ifdef SSR
            vec4 reflectionColor = roughReflection(viewPos.xyz, info.normal, fract(frameTimeCounter * 4.0 + interleavedGradientNoise(gl_FragCoord.xy)), roughness*4.0, colortex0);
            #else
            vec4 reflectionColor = vec4(0.0);
            #endif
            vec3 skyReflectionColor = vec3(0.0);
            if (reflectionColor.a < 0.5) {
                #if WORLD == 0

                skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal));
                if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                    skyReflectionColor *= clamp01((eyeBrightnessSmooth.y-9)/55.0);
                } else if (eyeBrightnessSmooth.y <= 8) {
                    skyReflectionColor *= 0.0;
                }

                #endif
            }
            float fresnel = fresnel_schlick(viewPos.xyz, info.normal, clamp(info.specular.g, 0.0, 0.898039));
            color += mix(vec3(0.0), mix(vec3(0.0), reflectionColor.rgb, reflectionColor.a)+skyReflectionColor, clamp01(fresnel+0.1-(roughness*2.0)));
        }
        #endif
    }
    #endif

    // draw water fog
    if (isEyeInWater == 1) {
        vec3 transmittance = exp(-vec3(1.0, 0.2, 0.1) * length(viewPos.xyz));
        color *= transmittance;
    }
    #ifdef FOG 

    #if WORLD == 0
    else if (isEyeInWater == 0 && depth0 != 1.0) {
        vec3 fogCol = texture2DLod(colortex2, texcoord*0.1, 6.0).rgb*2.0;
        if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
            fogCol = mix(vec3(0.1), fogCol, clamp01((eyeBrightnessSmooth.y-9)/55.0));
        } else if (eyeBrightnessSmooth.y <= 8) {
            fogCol = vec3(0.1);
        }
        color = mix(color, fogCol, clamp01(length(viewPos.xyz)/196.0*FOG_DENSITY));
    }
    #elif WORLD == -1
    else if (isEyeInWater == 0 && depth0 != 1.0) {
        color = mix(color, fogColor, clamp01(length(viewPos.xyz)/84.0*FOG_DENSITY));
    }
    #endif

    #endif

    colorOut = color;
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec4 times;
out vec3 lightColor;
out vec3 ambientColor;

// Uniforms
uniform float sunAngle;
uniform float rainStrength;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

void main() {
    gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    calcLightingColor(sunAngle, rainStrength, sunPosition, shadowLightPosition, ambientColor, lightColor, times);
}

#endif