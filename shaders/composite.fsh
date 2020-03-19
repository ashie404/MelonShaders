#version 120

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;

#include "lib/settings.glsl"
#include "lib/framebuffer.glsl"

/* DRAWBUFFERS:012 */

struct Fragment {
    vec3 albedo;
    vec3 normal;
    float emission;
};

struct Lightmap {
    float blockLightStrength;
    float skyLightStrength;
};

Fragment getFragment(in vec2 coord) {
    Fragment fragment;

    fragment.albedo = getAlbedo(coord);
    fragment.normal = getNormal(coord);
    fragment.emission = getEmission(coord);

    return fragment;
}

Lightmap getLightmapSample(in vec2 coord) {
    Lightmap lightmap;

    lightmap.blockLightStrength = getBlockLightStrength(coord);
    lightmap.skyLightStrength = getSkyLightStrength(coord);

    return lightmap;
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap) {
    float directLightStrength = dot(frag.normal, lightVector);
    directLightStrength = max(0.0, directLightStrength);
    vec3 directLight = directLightStrength * lightColor;

    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.1;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    vec3 color = frag.albedo * (directLight + skyLight + blockLight);
    return mix(color, frag.albedo, frag.emission);
}

void main() {
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);
    vec3 finalColor = calculateLighting(frag, lightmap);

    // output
    GCOLOR_OUT = vec4(finalColor, 1.0);
}