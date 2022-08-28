// directional lightmap code from BSL shaders ( https://bitslablab.com/ )
mat3 getLightmapTBN(vec3 viewPos){
    mat3 lmTBN = mat3(normalize(dFdx(viewPos)), normalize(dFdy(viewPos)), vec3(0.0));
    lmTBN[2] = cross(lmTBN[0], lmTBN[1]);
    return lmTBN;
}

float directionalLightmap(float lightmap, float lightmapRaw, vec3 normal, mat3 lightmapTBN) {
    if (lightmap < 0.001) return lightmap;

    vec2 deriv = vec2(dFdx(lightmapRaw), dFdy(lightmapRaw)) * 256.0;
    vec3 dir = normalize(vec3(
        deriv.x * lightmapTBN[0] +
        0.0005  * lightmapTBN[2] +
        deriv.y * lightmapTBN[1]
    ));
    
    float pwr = clamp(dot(normal, dir), -1.0, 1.0);
    if (abs(pwr) > 0.0)
        pwr = pow(abs(pwr), 2.0-DIRECTIONAL_LIGHTMAP_STRENGTH) * sign(pwr) * lightmap;
    if (length(deriv) > 0.001)
        lightmap = pow(lightmap, max(1.0 - pwr, 0.001));

	return lightmap;
}