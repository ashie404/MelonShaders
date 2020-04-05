mat3 getLightmapTBN(vec3 viewPos){
    mat3 lmTBN = mat3(normalize(dFdx(viewPos)), normalize(dFdy(viewPos)), vec3(0.0));
    lmTBN[2] = cross(lmTBN[0], lmTBN[1]);
    return lmTBN;
}

float directionalLightmap(float rawLightmap, vec3 normal, mat3 lightmapTBN){
    float lightmap = clamp01(rawLightmap);
    
    if(lightmap < 0.001) return lightmap;

    // get derivative of lightmap
    vec2 deriv = vec2(dFdx(rawLightmap), dFdy(rawLightmap)) * 256.0;

    // calculate light direction using lightmap tbn matrix
    vec3 dir = normalize(vec3(deriv.x * lightmapTBN[0] +
                              0.0005  * lightmapTBN[2] +
                              deriv.y * lightmapTBN[1]));

    // lambertian diffuse \o/
    float pwr = dot(normal, dir);

    // give the lightmap directional power
    lightmap *= pwr;

    // mix so it doesnt look bad

    // make directional lightmap fade properly
    lightmap = mix(0.0, lightmap, clamp01(rawLightmap/64));

    // mix directional lightmap with vanilla lightmap
    lightmap = mix(lightmap, rawLightmap, (2.0 - DIRECTIONAL_LIGHTMAP_STRENGTH) / 200);

	return lightmap*64;
}