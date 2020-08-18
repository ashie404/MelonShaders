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
const bool colortex2MipmapEnabled = true;
#ifndef MICROFACET_REFL
const bool colortex0MipmapEnabled = true;
#endif
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
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

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
uniform vec3 cameraPosition;

uniform vec3 fogColor;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;

uniform float eyeAltitude;
uniform float sunAngle;

uniform int isEyeInWater;
uniform int frameCounter;

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/vertex/distortion.glsl"
#include "/lib/fragment/reflection.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/atmosphere.glsl"
#include "/lib/fragment/volumetrics.glsl"
#include "/lib/fragment/shading.glsl"

void main() {
    float depth0 = texture2D(depthtex0, texcoord).r;

    FragInfo info = getFragInfo(texcoord);

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    shadowPos /= shadowPos.w;

    vec3 color = info.albedo.rgb;

    #ifdef REFLECTIONS
    if (depth0 != 1.0) {
        float roughness = pow(1.0 - info.specular.r, 2.0);
        if (info.matMask == 3) {

            // calculate water reflections
            #ifdef SSR
            vec4 reflectionColor = reflection(viewPos.xyz, info.normal, fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy)), colortex0);
            #else
            vec4 reflectionColor = vec4(0.0);
            #endif
            vec3 skyReflectionColor = vec3(0.0);

            if (reflectionColor.a < 0.5 && isEyeInWater == 0) {
                #if WORLD == 0

                skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal), 6);
                calculateCelestialBodies(reflect(viewPos.xyz, info.normal), reflect(worldPos.xyz, mat3(gbufferModelViewInverse)*info.normal), skyReflectionColor);
                skyReflectionColor *= info.lightmap.y;

                #else
                
                skyReflectionColor = fogColor*0.5;

                #endif
            }

            float fresnel = fresnel_schlick(viewPos.xyz, info.normal, 0.02);

            color += mix(vec3(0.0), mix(skyReflectionColor, reflectionColor.rgb, reflectionColor.a), fresnel);

        } 
        #ifdef SPECULAR
        else {
            bool isMetal = (info.specular.g >= 230.0 / 255.0);

            vec3 albedo = pow(decodeColor(texture2D(colortex4, texcoord).w), vec3(2.0));

            // SPECULAR HIGHLIGHTS //

            #if WORLD == 0

            vec3 shadowsDiffuse = getShadowsDiffuse(info, viewPos.xyz, shadowPos.xyz);
            float specularStrength = ggx(info.normal, normalize(viewPos.xyz), normalize(shadowLightPosition), info.specular.g, info.specular.r);
            vec3 specularColor = vec3(0.0);

            if (!isMetal) {
                specularColor = (lightColor * specularStrength * (isEyeInWater == 1 ? exp(-waterCoeff * length(viewPos.xyz)) : vec3(1.0))) * shadowsDiffuse;
            } else {
                specularColor = (lightColor * specularStrength * albedo * (isEyeInWater == 1 ? exp(-waterCoeff * length(viewPos.xyz)) : vec3(1.0))) * shadowsDiffuse;
            }

            color += specularColor;

            #endif

            // SPECULAR REFLECTIONS //
            #ifdef SPEC_REFLECTIONS
            if (roughness <= 0.325) {
                // screenspace reflection calculation
                #ifdef SSR
                vec4 reflectionColor = roughReflection(viewPos.xyz, info.normal, fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy)), roughness, colortex0);
                #else
                vec4 reflectionColor = vec4(0.0);
                #endif

                vec3 skyReflectionColor = vec3(0.0);

                // calculate sky reflection color if there is no SSR data here
                if (reflectionColor.a < 0.5) {
                    #if WORLD == 0

                    skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal), 6);
                    skyReflectionColor *= info.lightmap.y;

                    #else

                    skyReflectionColor = fogColor*0.5;

                    #endif
                }

                // apply water fog color to sky reflection color when underwater, so reflections dont look weird underwater
                if (isEyeInWater == 1) {
                    skyReflectionColor *= exp(-waterCoeff * length(viewPos.xyz));
                }

                // prevent sky reflection from being literally black
                skyReflectionColor = max(skyReflectionColor, vec3(0.01));
                
                float fresnel = fresnel_schlick(viewPos.xyz, info.normal, info.specular.g);

                // combine reflection
                vec3 reflection = mix(skyReflectionColor, reflectionColor.rgb, reflectionColor.a);

                if (isMetal) {
                    // metal
                    #if WORLD == 0
                    vec3 metalReflection = reflection*albedo+specularColor;
                    #else
                    vec3 metalReflection = reflection*albedo;
                    #endif
                    calculateFog(metalReflection, viewPos.xyz, depth0, true);
                    color = mix(color, metalReflection, clamp01(fresnel+0.3));
                } else {
                    // dielectric
                    #if WORLD == 0
                    reflection += specularColor;
                    #endif
                    calculateFog(reflection, viewPos.xyz, depth0, true);
                    color = mix(color, reflection, clamp01(fresnel));
                }
            }
            #endif
        }
        #endif
        
    }
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