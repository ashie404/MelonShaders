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
    if (worldTime >= 23645 || worldTime <= 12400) {
        lightVec = normalize(sunPosition);
        lightCol = vec3(4.5);
        skyCol = vec3(0.022, 0.025, 0.06);
        night = 0;
    } else if (worldTime >= 12820 && worldTime <= 23200) {
        lightVec = normalize(moonPosition);
        lightCol = vec3(0.7);
        skyCol = vec3(0.0022, 0.0025, 0.006);
        night = 1;
    } else {
        float transition = smoothstep(50,820,abs(abs(float(worldTime)-17990)-5220));
        if (transition > 0.5) {
            lightVec = normalize(moonPosition);
        } else {
            lightVec = normalize(sunPosition);
        }
        night = transition;
        lightCol = mix(vec3(0.7), vec3(4.5), transition);
        skyCol = mix(vec3(0.0022, 0.0025, 0.006), vec3(0.022, 0.025, 0.06), transition);
    }
}
void desaturateNight(out float desaturationAmt) {
    if (worldTime >= 23645 || worldTime <= 12400) {
        desaturationAmt = 0;
    } else if (worldTime >= 12820 && worldTime <= 23200) {
        desaturationAmt = NIGHT_DESATURATION;
    } else {
        float transition = smoothstep(50,820,abs(abs(float(worldTime)-17990)-5220));
        desaturationAmt = mix(NIGHT_DESATURATION, 0, transition);
    }
}
#endif
