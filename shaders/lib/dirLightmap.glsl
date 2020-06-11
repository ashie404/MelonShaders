/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

mat3 getLightmapTBN(vec3 viewPos){
    mat3 lmTBN = mat3(normalize(dFdx(viewPos)), normalize(dFdy(viewPos)), vec3(0.0));
    lmTBN[2] = cross(lmTBN[0], lmTBN[1]);
    return lmTBN;
}

float directionalLightmap(float rawLightmap, vec3 normal, mat3 lightmapTBN){
    float lightmap = clamp01(rawLightmap);
    
    if(lightmap < 0.001) return lightmap;

    // get derivative of lightmap
    vec2 deriv = vec2(dFdx(rawLightmap), dFdy(rawLightmap));

    // calculate light direction using lightmap tbn matrix
    vec3 dir = vec3(deriv.x * lightmapTBN[0] +
                              deriv.y * lightmapTBN[1]);
    if (length(dir) == 0.0) {
        dir = normalize(vec3(0.0005 * lightmapTBN[2]));
    } else {
        dir = normalize(dir);
    }

    // lambertian diffuse \o/
    float pwr = dot(normal, dir);

    // give the lightmap directional power
    lightmap *= pwr;

    // make directional lightmap fade properly
    lightmap = mix(0.0, lightmap, clamp01(rawLightmap/16));

    // mix directional lightmap with vanilla lightmap
    lightmap = mix(lightmap, rawLightmap, (2.0 - DIRECTIONAL_LIGHTMAP_STRENGTH) / 32.0);

	return clamp01(lightmap*32.0);
}