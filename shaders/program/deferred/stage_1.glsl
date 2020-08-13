/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:05 */
layout (location = 0) out vec3 colorOut;
layout (location = 1) out vec3 rtaoOut;

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

uniform float eyeAltitude;
uniform float sunAngle;

uniform int isEyeInWater;

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
        vec3 current = clamp01(calcRTAO(viewPos.xyz, normalize(info.normal)));
        vec3 history = texture2D(colortex5, reprojectCoords(screenPos.xyz * 0.5 + 0.5)).rgb;

        vec4 previousPosition = vec4(worldPos.xyz + cameraPosition, worldPos.w);
        previousPosition.xyz -= previousCameraPosition;
        previousPosition = gbufferPreviousModelView * previousPosition;
        previousPosition = gbufferPreviousProjection * previousPosition;
        previousPosition /= previousPosition.w;

        vec2 velocity = (screenPos - previousPosition).xy * 0.02;
        velocity = clamp01(normalize(velocity)*length(velocity)*128.0);

        rtaoOut = mix(current, history, clamp01(0.75-clamp01(velocity.x+velocity.y)));
        
        #else
        rtaoOut = texture2D(colortex5, texcoord).rgb;
        #endif
    } else {
        color = texture2D(colortex2, texcoord*0.1).rgb;
        calculateCelestialBodies(viewPos.xyz, worldPos.xyz, color);
        calculateClouds(worldPos.xyz, color);
    }
    
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