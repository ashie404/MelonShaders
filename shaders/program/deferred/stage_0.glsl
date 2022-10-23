/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

#ifndef SKYTEX
/* RENDERTARGETS: 2 */
out vec3 atmosphereOut;
#else
// idk why the fuck but i have to draw to a buffer, so if skytex
// enabled just draw to buffer 9 we dont use that lol
/* RENDERTARGETS: 9 */
#endif

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

uniform vec3 fogColor;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

uniform float eyeAltitude;

// Includes
#include "/lib/util/noise.glsl"
#include "/lib/fragment/atmosphere.glsl"

void main() {
    float depth0 = texture2D(depthtex0, texcoord).r;

    vec4 screenPos = vec4(texcoord, depth0, 1.0) * 2.0 - 1.0;
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    
    #if WORLD == 0
    
    #ifndef SKYTEX
    vec3 color = getSkyColor(viewPos.xyz, 15);
    atmosphereOut = color;
    #endif

    #elif WORLD == -1
    atmosphereOut = fogColor;
    #elif WORLD == 1
    atmosphereOut = fogColor;
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