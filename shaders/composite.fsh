#version 120

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;

#include "lib/settings.glsl"
#include "lib/framebuffer.glsl"
#include "lib/common.glsl"
#include "lib/shadow.glsl"

/* DRAWBUFFERS:012 */

void main() {
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);
    vec3 finalColor = calculateLighting(frag, lightmap);

    // output
    GCOLOR_OUT = vec4(finalColor, 1.0);
}