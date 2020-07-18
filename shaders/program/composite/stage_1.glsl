/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colorOut;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float far;
uniform float near;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform int isEyeInWater;
uniform float rainStrength;
uniform float centerDepthSmooth;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform vec3 fogColor;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;

in vec4 times;

#define linear(x) (2.0 * near * far / (far + near - (2.0 * x - 1.0) * (far - near)))

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/noise.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/poisson.glsl"
#include "/lib/shading.glsl"
#include "/lib/atmosphere.glsl"

#include "/lib/raytrace.glsl"
#include "/lib/reflection.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    float depth0 = texture2D(depthtex0, texcoord).r;

    vec4 screenPos = vec4(vec3(texcoord, depth0) * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    
    // if not sky check for translucents
    if (depth0 != 1.0) {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);

        // if water, draw reflections
        if (frag.matMask == 3) {
            if (isEyeInWater == 0) {
                // get sky reflection
                vec3 reflectedPos = reflect(viewPos.xyz, frag.normal);
                vec3 reflectedPosWorld = (gbufferModelViewInverse * vec4(reflectedPos, 1.0)).xyz;

                vec3 skyReflection = getSkyColor(reflectedPosWorld, normalize(reflectedPosWorld), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, false, true);

                // make sky reflection darker if in cave mode

                if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                    skyReflection *= clamp01((eyeBrightnessSmooth.y-9)/55.0);
                } else if (eyeBrightnessSmooth.y <= 8) {
                    skyReflection *= 0.0;
                }

                // combine reflections
                #ifdef SSR
                vec4 reflectionColor = reflection(viewPos.xyz, frag.normal, bayer64(gl_FragCoord.xy), colortex0);
                color += mix(vec3(0.0), mix(mix(vec3(0.0), skyReflection, 0.25), reflectionColor.rgb, reflectionColor.a), 0.5);
                #else
                color += mix(vec3(0.0), skyReflection, 0.05);
                #endif

                applyFog(viewPos.xyz, worldPos.xyz, depth0, color);
            }
        }

        #ifdef SSR
        #ifdef SPECULAR
        // specular reflections
        float roughness = pow(1.0 - pbr.smoothness, 2.0);
        if (roughness <= 0.125 && frag.matMask != 3.0 && frag.matMask != 4.0) {
            #if WORLD == 0
            vec3 reflectedPos = reflect(viewPos.xyz, frag.normal);
            vec3 reflectedPosWorld = (gbufferModelViewInverse * vec4(reflectedPos, 1.0)).xyz;
            vec3 skyReflection = getSkyColor(reflectedPosWorld, normalize(reflectedPosWorld), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, false, false);
            #elif WORLD == -1
            vec3 skyReflection = fogColor*0.5;
            #endif

            // make sky reflection darker if in cave mode
            #if WORLD == 0
            if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                skyReflection *= clamp01((eyeBrightnessSmooth.y-9)/55.0);
            } else if (eyeBrightnessSmooth.y <= 8) {
                skyReflection *= 0.0;
            }
            #endif

            vec4 reflectionColor = roughReflection(viewPos.xyz, frag.normal, fract(frameTimeCounter * 8.0 + bayer64(gl_FragCoord.xy)), roughness*8.0, colortex0);

            float fresnel = clamp(fresnel(0.2, 0.1, 1.0, viewPos.xyz, frag.normal)+0.5, 0.15, 1.0);

            color *= mix(vec3(1.0), mix(skyReflection, reflectionColor.rgb, reflectionColor.a), clamp01((1.0-roughness*4.0)-(1.0-SPECULAR_REFLECTION_STRENGTH)-(1.0-fresnel)));

            if (isEyeInWater == 0) applyFog(viewPos.xyz, worldPos.xyz, depth0, color);
        }
        #endif
        #endif
    }

    colorOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;
out vec3 ambientColor;
out vec3 lightColor;
out vec4 times;

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