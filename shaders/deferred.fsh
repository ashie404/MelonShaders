#version 120

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
uniform int worldTime;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;

uniform sampler2D gdepthtex;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

uniform vec3 cameraPosition;

uniform vec3 upPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;

varying vec3 normal;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow.glsl"
#include "/lib/distort.glsl"

void main() {
    float z = texture2D(depthtex0, texcoord.st).r;
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);

    // calculate distorted shadow coordinate
    vec4 pos = vec4(vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r) * 2.0 - 1.0, 1.0);
    pos = gbufferProjectionInverse * pos;
    pos = gbufferModelViewInverse * pos;
    pos = shadowModelView * pos;
    pos = shadowProjection * pos;
    pos /= pos.w;
    vec3 shadowPos = distort(pos.xyz) * 0.5 + 0.5;

    float lightDot = dot(normalize(shadowLightPosition), normal);
    vec4 fShadowPos = vec4(shadowPos, 0);
    if (lightDot > 0.0) {
        fShadowPos = vec4(shadowPos, 1.0);
    }
    else {
        fShadowPos = vec4(shadowPos, 0);
    }
    vec3 finalColor = calculateLighting(frag, lightmap, fShadowPos);

    /*DRAWBUFFERS:0*/
    gl_FragData[0] = vec4(finalColor, 1);

    #ifdef SCREENSPACE_REFLECTIONS
    /*DRAWBUFFERS:05*/
	gl_FragData[1] = vec4(pow(finalColor, vec3(0.125)) * 0.5, float(z < 1.0)); //gaux2
    #endif
}