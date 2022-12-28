/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0,4,5 */
out vec3 colorOut;
out vec4 normalOut;
out vec3 rtaoOut;

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
uniform float far;
uniform float near;
uniform float rainStrength;


uniform float eyeAltitude;
uniform float sunAngle;

uniform int isEyeInWater;
uniform int frameCounter;


// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/vertex/distortion.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/atmosphere.glsl"
#include "/lib/fragment/ambientOcclusion.glsl"
#include "/lib/post/taaUtil.glsl"

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

    rtaoOut = vec3(1.0);

    if (depth0 != 1.0) {
        #ifdef RTAO
        // RTAO accumulation stuff
        vec2 reprojCoord = reprojectCoords(screenPos.xyz * 0.5 + 0.5);

        vec3 current = clamp01(calcRTAO(viewPos.xyz, normalize(info.normal)));
        vec3 history = texture2D(colortex5, reprojCoord).rgb;

        #ifdef RTAO_FILTER 
            vec3 currentNormal = mat3(gbufferModelView) * (texture2D(colortex4, reprojCoord).xyz * 2.0 - 1.0);
            float currentDepth = texture2D(depthtex0, reprojCoord).x;

            vec3 filtered = vec3(0.0);
            vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);
            for (int i = 0; i < 4; i++) {
                vec2 offset = (vogelDiskSample(i, 4, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter))) * oneTexel * 2.0;
                vec3 filterNormal = mat3(gbufferModelView) * (texture2D(colortex4, reprojCoord + offset).xyz * 2.0 - 1.0);
                float filterDepth = texture2D(depthtex0, reprojCoord + offset).x;

                filtered += all(greaterThanEqual(currentNormal+vec3(0.05), filterNormal))
                            && all(lessThanEqual(currentNormal-vec3(0.05), filterNormal))
                            && filterDepth >= currentDepth-0.001 && filterDepth <= currentDepth+0.001
                    ? texture2D(colortex5, reprojCoord + offset).rgb
                    : history;
            }
            filtered /= 4.0;

            history = filtered;
        #endif

        vec4 previousPosition = vec4(worldPos.xyz + cameraPosition, worldPos.w);
        previousPosition.xyz -= previousCameraPosition;
        previousPosition = gbufferPreviousModelView * previousPosition;
        previousPosition = gbufferPreviousProjection * previousPosition;
        previousPosition /= previousPosition.w;

        vec2 velocity = (screenPos - previousPosition).xy * 0.02;
        velocity = clamp01(normalize(velocity)*length(velocity)*1024.0);


        #ifdef RTAO_FILTER
        rtaoOut = mix(current, history, clamp01(0.95-clamp(velocity.x+velocity.y, 0.0, 0.45)));
        #else
        rtaoOut = mix(current, history, clamp01(0.85-clamp(velocity.x+velocity.y, 0.0, 0.45)));
        #endif

        #else
        rtaoOut = texture2D(colortex5, texcoord).rgb;
        #endif
    } else {
        #ifndef SKYTEX
        color = texture2D(colortex2, texcoord*0.1).rgb;
        calculateCelestialBodies(true, viewPos.xyz, worldPos.xyz, color);
        calculateClouds(false, worldPos.xyz, color);
        #else
        color = texture2D(colortex2, texcoord).rgb;
        calculateCelestialBodiesNoStars(viewPos.xyz, worldPos.xyz, color);
        #endif
    }
    vec3 enchantc = vec3(0.0);
     if (texture2D(colortex3, texcoord).r > 0.5) {
        enchantc = 
        vec3(pow(cellular(((worldPos.xyz)*8.0+vec3(vogelDiskSample(1, 4, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter)), 0.0))+frameTimeCounter*0.5), 4.0)*8.0);
        enchantc.r *= ENCHANT_R;
        enchantc.g *= ENCHANT_G;
        enchantc.b *= ENCHANT_B;
        enchantc.rgb *= ENCHANT_I*0.7;
    }
    
    colorOut = color;
    normalOut = vec4(texture2D(colortex4, texcoord).rgb, encodeColor(enchantc));
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