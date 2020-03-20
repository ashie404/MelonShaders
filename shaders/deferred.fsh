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

uniform float viewWidth;
uniform float viewHeight;

varying vec3 normal;

#include "lib/settings.glsl"
#include "lib/framebuffer.glsl"
#include "lib/common.glsl"
#include "lib/shadow.glsl"

void main() {
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);
    vec3 finalColor = calculateLighting(frag, lightmap);

    GCOLOR_OUT = vec4(finalColor, 1);
}