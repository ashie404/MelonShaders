/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

const bool colortex2MipmapEnabled = true;
#ifndef MICROFACET_REFL
const bool colortex0MipmapEnabled = true;
#endif

/* RENDERTARGETS: 0,2,8 */
out vec3 colorOut;
out vec3 bloomOut;
out vec4 reflecOut;

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
uniform sampler2D colortex8;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform vec3 fogColor;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;

uniform float eyeAltitude;
uniform float sunAngle;
uniform float rainStrength;

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
#include "/lib/post/taaUtil.glsl"

// other things
mat2x3 getHardcodedMetal(float specG) {
    if      (specG == 230.0/255.0) return mat2x3(vec3(2.9114, 2.9497, 2.5845), vec3(3.0893, 2.9318, 2.7670));    // iron
    else if (specG == 231.0/255.0) return mat2x3(vec3(0.18299, 0.42108, 1.3734), vec3(3.4242, 2.3459, 1.7704));  // gold
    else if (specG == 232.0/255.0) return mat2x3(vec3(1.3456, 0.96521, 0.61722), vec3(7.4746, 6.3995, 5.3031));  // aluminum
    else if (specG == 233.0/255.0) return mat2x3(vec3(3.1071, 3.1812, 2.3230), vec3(3.3314, 3.3291, 3.1350));    // chrome
    else if (specG == 234.0/255.0) return mat2x3(vec3(0.27105, 0.67693, 1.3164), vec3(3.6092, 2.6248, 2.2921));  // copper
    else if (specG == 235.0/255.0) return mat2x3(vec3(1.9100, 1.8300, 1.4400), vec3(3.5100, 3.4000, 3.1800));    // lead
    else if (specG == 236.0/255.0) return mat2x3(vec3(2.3757, 2.0847, 1.8453), vec3(4.2655, 3.7153, 3.1365));    // platinum
    else if (specG == 237.0/255.0) return mat2x3(vec3(0.15943, 0.14512, 0.13547), vec3(3.9291, 3.1900, 2.3808)); // silver
    else return mat2x3(0.0);
}

// from http://wscg.zcu.cz/WSCG2005/Papers_2005/Short/H29-full.pdf
vec3 fresnel_metal(vec3 N, vec3 K, float cosTheta) {
    vec3 a = pow(N-1.0, vec3(2.0))+(4.0*N)*pow(1.0-cosTheta, 5.0)+pow(K, vec3(2.0));
    vec3 b = pow(N+1.0, vec3(2.0))+pow(K, vec3(2.0));

    return clamp01(a/b);
}

void main() {
    float depth0 = texture2D(depthtex0, texcoord).r;
    float depth1 = texture2D(depthtex1, texcoord).r;


    FragInfo info = getFragInfo(texcoord);

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    #ifdef PXL_SHADOWS
    vec4 shadowPos = shadowProjection * shadowModelView * vec4(
        (floor((worldPos.xyz+cameraPosition)*PXL_SHADOW_RES+0.05)+0.3)/PXL_SHADOW_RES-cameraPosition,
        worldPos.w);
    #else
    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    #endif
    shadowPos /= shadowPos.w;

    vec3 color = info.albedo.rgb;

    vec4 reflectionColor = vec4(0.0);
    vec4 filtered = vec4(0.0);

    #ifdef REFLECTIONS
    if (depth0 != 1.0 && info.matMask != 6 && info.matMask != 8) {
        float roughness = pow(1.0 - info.specular.r, 2.0);
        if (info.matMask == 3) {

            // calculate water reflections
            #ifdef SSR
            reflectionColor = reflection(viewPos.xyz, info.normal, fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy)), colortex0);
            #else
            reflectionColor = vec4(0.0);
            #endif
            vec3 skyReflectionColor = vec3(0.0);

            if (reflectionColor.a < 0.5 && isEyeInWater == 0) {
                #if WORLD == 0

                #ifndef SKYTEX

                    skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal), 6);
                    calculateCelestialBodies(false, reflect(viewPos.xyz, info.normal), reflect(worldPos.xyz, mat3(gbufferModelViewInverse)*info.normal), skyReflectionColor);
                    #ifdef CLOUD_REFLECTIONS
                    calculateClouds(true, reflect(worldPos.xyz, mat3(gbufferModelViewInverse)*info.normal), skyReflectionColor);
                    #endif
                
                #else

                    skyReflectionColor = texture2DLod(colortex2, vec2(texcoord.x, 1.0 - texcoord.y), 6.0).rgb;

                #endif
                
                skyReflectionColor *= info.lightmap.y;

                #else
                
                skyReflectionColor = vec3(0.01);

                #endif
            }

            float fresnel = fresnel_schlick(viewPos.xyz, info.normal, 0.02);

            color += mix(vec3(0.0), mix(skyReflectionColor, reflectionColor.rgb, reflectionColor.a), fresnel);
            color += ggx(info.normal, normalize(viewPos.xyz), normalize(shadowLightPosition), 0.02, 0.99)*(lightColor*0.4)*getShadowsDiffuse(info, viewPos.xyz, shadowPos.xyz);

        } 
        #ifdef SPECULAR
        else if (info.matMask != 4) {
            if (info.matMask == 7 && roughness > 0.95) {
                roughness = 0.0; // fixed roughness value for ice blocks
                info.specular.r = 0.995;
            }
            
            #ifdef REFL_FILTER
                vec2 reprojCoord = reprojectCoords(vec3(texcoord, texture2D(depthtex0, texcoord).r));
                vec4 previousReflection = texture2D(colortex8, reprojCoord);
                vec3 currentNormal = mat3(gbufferModelView) * (texture2D(colortex4, reprojCoord).xyz * 2.0 - 1.0);
                vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

                float filterSize = (roughness < 0.1 ? 0.5 : 2.0);

                for (int i = 0; i < 4; i++) {
                    vec2 offset = (vogelDiskSample(i, 4, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter))) * oneTexel * filterSize;
                    vec3 filterNormal = mat3(gbufferModelView) * (texture2D(colortex4, reprojCoord + offset).xyz * 2.0 - 1.0);
                    if (all(equal(currentNormal, filterNormal)))
                        filtered += texture2D(colortex8, reprojCoord + offset);
                    else
                        filtered += previousReflection;
                }
                filtered /= 4.0;
            #endif

            bool isMetal = (info.specular.g >= 230.0 / 255.0);
            bool isHardcoded = (isMetal && (info.specular.g < 238.0/255.0));

            vec3 albedo = toLinear(decodeColor(texture2D(colortex4, texcoord).w));

            #ifdef HARDCODED_METALS
            if (isHardcoded) {
                mat2x3 hardcodedData = getHardcodedMetal(info.specular.g);
                albedo = pow(fresnel_metal(hardcodedData[0], hardcodedData[1], clamp01(dot(info.normal, -normalize(viewPos.xyz)))), vec3(2.0));
            }
            #endif

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
            if (roughness <= 0.35) {
                // screenspace reflection calculation
                #ifdef SSR
                reflectionColor = roughReflection(viewPos.xyz, 
                    info.normal, 
                    fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy)), 
                    roughness, colortex0, 0.1, roughness <= 0.225 ? 1.5 : 2.0);
                #endif

                vec3 skyReflectionColor = vec3(0.0);

                // calculate sky reflection color if there is no SSR data here
                if (reflectionColor.a < 0.5) {
                    #if WORLD == 0

                    #ifndef SKYTEX

                        skyReflectionColor = getSkyColor(reflect(viewPos.xyz, info.normal), 6);
                        #ifdef CLOUD_REFLECTIONS
                        calculateClouds(true, reflect(worldPos.xyz, mat3(gbufferModelViewInverse)*info.normal), skyReflectionColor);
                        #endif

                    #else

                        skyReflectionColor = texture2DLod(colortex2, vec2(texcoord.x, 1.0 - texcoord.y), 6.0).rgb;

                    #endif

                    skyReflectionColor *= info.lightmap.y;

                    #else

                    skyReflectionColor = vec3(0.01);

                    #endif
                }

                // apply water fog color to sky reflection color when underwater, so reflections dont look weird underwater
                skyReflectionColor *= isEyeInWater == 1 ? exp(-waterCoeff * length(viewPos.xyz)) : vec3(1.0);

                // prevent sky reflection from being literally black
                skyReflectionColor = max(skyReflectionColor, vec3(0.002));
                
                float fresnel = fresnel_schlick(viewPos.xyz, info.normal, info.specular.g);

                // combine reflection
                #ifdef REFL_FILTER
                    vec3 reflection = mix(skyReflectionColor, previousReflection.rgb, previousReflection.a);
                #else
                    vec3 reflection = mix(skyReflectionColor, reflectionColor.rgb, reflectionColor.a);
                #endif

                if (isMetal) {
                    // metal
                    vec3 metalReflection = reflection*albedo;
                    
                    #if WORLD == 0
                    metalReflection += specularColor;
                    #endif

                    calculateFog(metalReflection, viewPos.xyz, worldPos.xyz, depth0, depth1, true);
                    color = metalReflection;
                } else {
                    // dielectric
                    #if WORLD == 0
                    reflection += specularColor;
                    #endif
                    calculateFog(reflection, viewPos.xyz, worldPos.xyz, depth0, depth1, true);
                    color = mix(color, reflection, clamp01(fresnel));
                }
            }
            #endif
        }
        #endif
        
    }
    #endif

    colorOut = color;
    #ifdef REFL_FILTER
        reflecOut = mix(filtered, reflectionColor, 0.2);
    #endif  
    #ifdef BLOOM
    vec3 bloomSample = color.rgb * clamp01(pow(luma(color.rgb), 4.0));
    bloomOut = bloomSample;
    #endif
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