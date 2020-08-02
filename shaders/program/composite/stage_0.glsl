/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:0 */
layout (location = 0) out vec3 colorOut;

/*
const bool colortex2MipmapEnabled = true;
*/

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

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
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

uniform int isEyeInWater;

// Defines
#define linear(x) (2.0 * near * far / (far + near - (2.0 * x - 1.0) * (far - near)))

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/vertex/distortion.glsl"
#include "/lib/fragment/shading.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/volumetrics.glsl"

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

    // if not sky, check for translucents
    if (depth0 != 1.0) {
        // if just translucent, calculate shading
        if (info.matMask == 2.0) {
            color = calculateTranslucentShading(info, viewPos.xyz, shadowPos.xyz);
        } else if (info.matMask == 3.0) { // if water, calculate water stuff
            // render water fog
            float ldepth0 = linear(depth0);
            float ldepth1 = linear(texture2D(depthtex1, texcoord).r);

            float depthcomp = (ldepth1-ldepth0);

            // set color to no-translucents color
            color = texture2D(colortex3, texcoord).rgb;

            // if eye is not in water, render above-water fog and wave foam
            if (isEyeInWater == 0) {
                // calculate transmittance
                vec3 transmittance = exp(-waterCoeff * depthcomp);
                color = color * transmittance;

                // calculate water foam/lines color
                vec3 foamColor = ambientColor*WAVE_BRIGHTNESS;
                foamColor = mix(vec3(0.05), foamColor, eyeBrightnessSmooth.y/240.0);

                // water foam
                #ifdef WAVE_FOAM
                if (depthcomp <= 0.15) {
		            color += vec3(0.75) * foamColor;
		        } 
                #endif

                #ifdef WAVE_CAUSTICS
                vec3 worldPosCamera = worldPos.xyz + cameraPosition;

                #ifdef WAVE_PIXEL
                worldPosCamera = vec3(ivec3(worldPosCamera*WAVE_PIXEL_R)/WAVE_PIXEL_R);
                #endif

                worldPosCamera.y += frameTimeCounter*WAVE_SPEED;
                color += vec3(pow(cellular(worldPosCamera), 8.0/WAVE_CAUSTICS_D)) * 0.75 * foamColor;
                #endif
            }
        }
    }

    calculateFog(color, viewPos.xyz, depth0);
    
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