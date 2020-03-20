struct Fragment {
    vec3 albedo;
    vec3 normal;
    float emission;
    vec2 coord;
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
    fragment.coord = coord;

    return fragment;
}

Lightmap getLightmapSample(in vec2 coord) {
    Lightmap lightmap;

    lightmap.blockLightStrength = getBlockLightStrength(coord);
    lightmap.skyLightStrength = getSkyLightStrength(coord);

    return lightmap;
}

