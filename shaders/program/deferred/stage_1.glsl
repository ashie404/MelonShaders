/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:03 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 noTranslucentsOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec4 times;
in vec3 lightColor;
in vec3 ambientColor;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform sampler2D depthtex0;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

uniform float eyeAltitude;

// Includes
#include "/lib/fragment/fraginfo.glsl"
#include "/lib/vertex/distortion.glsl"
#include "/lib/fragment/shading.glsl"
#include "/lib/util/noise.glsl"
#include "/lib/fragment/atmosphere.glsl"

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

    if (depth0 != 1.0) {
        color = calculateShading(info, viewPos.xyz, shadowPos.xyz);
    } else {
        color = texture2D(colortex2, texcoord/4.0).rgb;

        #ifdef STARS
        float starNoise = cellular(normalize(worldPos.xyz)*32);
        if (starNoise <= 0.05) {
            color += mix(vec3(0.0), mix(vec3(0.0), vec3(cellular(normalize(worldPos.xyz)*16.0)), clamp01(1.0-starNoise)), clamp01(times.w));
        }
        #endif

        vec4 sunSpot = calculateSunSpot(normalize(viewPos.xyz), normalize(sunPosition), 0.35);
        vec4 moonSpot = calculateMoonSpot(normalize(viewPos.xyz), normalize(moonPosition), 0.5);

        // add sun and moon spots
        color += sunSpot.rgb*color;
        color += moonSpot.rgb;
    }
    
    colorOut = vec4(color, 1.0);
    noTranslucentsOut = vec4(color, 1.0);
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