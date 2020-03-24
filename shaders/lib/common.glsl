#ifndef VSH

struct Fragment {
    vec3 albedo;
    vec3 normal;
    float emission;
    float data;
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
#endif

#ifdef VSH

void dayNightCalc(out float night, out vec3 lightVec, out vec3 lightCol, out vec3 skyCol) {
    if (worldTime < 12700 || worldTime > 23250) {
        lightVec = normalize(sunPosition);
        lightCol = vec3(1.0);
        skyCol = vec3(0.012, 0.015, 0.03);
        night = 0;
    } else {
        lightVec = normalize(moonPosition);
        lightCol = vec3(0.1);
        skyCol = vec3(0.0012, 0.0015, 0.003);
        night = 1;
    }
}

#endif