/* 
    Melon Shaders by June
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:05 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 reflectionsOut;

/*
const float eyeBrightnessSmoothHalflife = 4.0;
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform int frameCounter;
uniform int isEyeInWater;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform ivec2 eyeBrightnessSmooth;

uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/poisson.glsl"
#include "/lib/shading.glsl"
#include "/lib/noise.glsl"
#include "/lib/atmosphere.glsl"
//#include "/lib/temporalUtil.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    float depth0 = texture2D(depthtex0, texcoord).r;

    vec4 screenPos = vec4(vec3(texcoord, depth0) * 2.0 - 1.0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    // if sky, draw sky. else, calculate shading.
    if (depth0 == 1.0) {
        #ifndef NETHER
        color = getSkyColor(worldPos.xyz, normalize(worldPos.xyz), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, false);
        #else
        color = vec3(0.1, 0.02, 0.015)*0.5;
        #endif
    } else {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);

        vec4 pos = shadowModelView * worldPos;
        pos = shadowProjection * pos;
        pos /= pos.w;
        vec3 shadowPos = distort(pos.xyz) * 0.5 + 0.5;

        color = calculateShading(frag, pbr, normalize(viewPos.xyz), shadowPos);
        if (isEyeInWater == 0) applyFog(viewPos.xyz, worldPos.xyz, depth0, color);
    }
    colorOut = vec4(color, 1.0);
    reflectionsOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;
out vec3 ambientColor;
out vec3 lightColor;

uniform float sunAngle;
uniform float rainStrength;

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    calcLightingColor(sunAngle, rainStrength, sunPosition, shadowLightPosition, ambientColor, lightColor);
}

#endif