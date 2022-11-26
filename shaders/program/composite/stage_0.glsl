/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0 */
out vec3 colorOut;

const bool colortex2MipmapEnabled = true;

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

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

uniform vec3 fogColor;

uniform ivec2 eyeBrightnessSmooth;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float eyeAltitude;
uniform float sunAngle;
uniform float far;
uniform float near;
uniform float wetness;

uniform int isEyeInWater;
uniform int frameCounter;

// Defines
#define linearDepth(x) (2.0 * near * far / (far + near - (2.0 * x - 1.0) * (far - near)))

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/vertex/distortion.glsl"
#include "/lib/fragment/shading.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/volumetrics.glsl"

void main() {
    float depth0 = texture2D(depthtex0, texcoord).r;
    float depth1 = texture2D(depthtex1, texcoord).r;

    FragInfo info = getFragInfo(texcoord);

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    // no-translucents positions
    vec4 screenPosNT = vec4(texcoord, depth1, 1.0) * 2.0 - 1.0;
    vec4 viewPosNT = gbufferProjectionInverse * screenPosNT;
    viewPosNT /= viewPosNT.w;

    #ifdef PXL_SHADOWS
    vec4 shadowPos = shadowProjection * shadowModelView * vec4(
        (floor((worldPos.xyz+cameraPosition)*PXL_SHADOW_RES+0.05)+0.3)/PXL_SHADOW_RES-cameraPosition,
        worldPos.w);
    #else
    vec4 shadowPos = shadowProjection * shadowModelView * worldPos;
    #endif
    shadowPos /= shadowPos.w;

    vec3 color = info.albedo.rgb;

    // if weather particle, meowmeowmeowmeow!!! :3
    if (info.matMask == 8) {
        // certified Kitty Magic
        color = calculateWeatherParticles(info, viewPos.xyz, shadowPos.xyz);
    }

    // if not sky, check for translucents
    if (depth0 != 1.0) {
        // if just translucent, calculate shading
        if (info.matMask == 2 || info.matMask == 5) {
            color = calculateTranslucentShading(info, viewPos.xyz, shadowPos.xyz);
        } else if (info.matMask == 3) { // if water, calculate water stuff

            // water fog vars
            float ldepth0 = linearDepth(depth0);
            float ldepth1 = linearDepth(depth1);

            float depthcomp = (ldepth1-ldepth0);

            color = texture2D(colortex3, texcoord).rgb;

            // if eye is not in water, render above-water fog and wave foam
            if (isEyeInWater < 0.5) {
                // calculate transmittance
                vec3 transmittance = exp(-waterCoeff * depthcomp);
                color *= transmittance;
                #ifdef VL
                vec3 scattering = calculateVL(viewPosNT.xyz, lightColor, false);
                scattering *= waterScatterCoeff; // scattering coefficent
                scattering *= (vec3(1.0) - transmittance) / waterCoeff;
                color += scattering;
                #endif

                // calculate water foam/lines color
                vec3 foamColor = ambientColor*WAVE_BRIGHTNESS;
                foamColor = mix(vec3(0.025), foamColor, info.lightmap.y);

                // water foam
                #ifdef WAVE_FOAM
                if (depthcomp <= 0.15) {
                    #ifdef WAVE_FOAM_FADE
		            color += vec3(0.75) * foamColor * clamp01(1.0 - depthcomp*6.66666666);
                    #else
                    color += vec3(0.75) * foamColor;
                    #endif
		        } 
                #endif

                #ifdef WAVE_CAUSTICS
                vec3 worldPosCamera = worldPos.xyz + cameraPosition;

                #ifdef WAVE_PIXEL
                worldPosCamera = vec3(ivec3(worldPosCamera*WAVE_PIXEL_R)/WAVE_PIXEL_R);
                #endif

                worldPosCamera.y += frameTimeCounter*(WAVE_SPEED+(wetness*1.5));
                color += vec3(pow(cellular(worldPosCamera), 8.0/WAVE_CAUSTICS_D)) * 0.75 * foamColor;
                #endif
            } 
            #ifdef SNELLS_WINDOW
            else {
                vec3 rayDir = refract(normalize(viewPos.xyz), info.normal, 1.33261354207);
                if (rayDir == vec3(0.0)) {
                    // none of this is actually realistic i just
                    // like how it looks

                    vec3 transmittance = exp(-waterCoeff * ldepth0);
                    color *= transmittance;
                    vec3 scattering = vec3(viewPos.w);
                    scattering *= waterScatterCoeff; // scattering coefficent
                    scattering *= (vec3(1.0) - transmittance) / waterCoeff;
                    color = pow(scattering, vec3(1.4));
                }
            }
            #endif
        } else if (info.matMask == 7) { // ice block handling to make them look less bad
            // water fog vars
            float ldepth0 = linearDepth(depth0);
            float ldepth1 = linearDepth(depth1);

            float depthcomp = (ldepth1-ldepth0);

            color = texture2D(colortex3, texcoord).rgb;
            if (isEyeInWater < 0.5) {
                // calculate transmittance
                vec3 transmittance = exp(-waterCoeff * depthcomp);
                color *= transmittance;
                #ifdef VL
                vec3 scattering = calculateVL(viewPosNT.xyz, lightColor, false);
                scattering *= waterScatterCoeff; // scattering coefficent
                scattering *= (vec3(1.0) - transmittance) / waterCoeff;
                color += scattering;
                #endif

                color = mix(color, calculateShading(info, viewPos.xyz, shadowPos.xyz, false), clamp01(pow(info.albedo.a, 4.0)));
            }
        }
    }

    calculateFog(color, viewPos.xyz, worldPos.xyz, depth0, false);
    
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