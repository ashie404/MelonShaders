struct PBRData {
    float smoothness;
    float F0;
    // todo: implement rest of labpbr spec lol
};

PBRData getPBRData(vec4 specularData) {
    PBRData pbrData;

    pbrData.smoothness = specularData.r;
    
    if (specularData.g <= 229) {
        pbrData.F0 = specularData.g;
    } else {
        pbrData.F0 = 0;
    }

    // todo: decode rest of labpbr spec

    return pbrData;
}

// todo: decode normal AO
vec3 decodeLabNormal(in vec3 normalTex, in mat3x3 tbnMat) {
    vec3 labNormal = normalTex * 2.0 - (254.0 * (1/255.0));
    labNormal.z  = sqrt(clamp01(1.0 - dot(labNormal.xy, labNormal.xy)));
    return normalize(labNormal * tbnMat);
}