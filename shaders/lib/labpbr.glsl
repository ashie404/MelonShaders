/*
    Melon Shaders by June
    https://juniebyte.cf
*/

struct PBRData {
    float smoothness;
    float F0;
};

PBRData getPBRData(vec4 specularData) {
    PBRData pbrData;

    pbrData.smoothness = specularData.r;
    
    if (specularData.g <= 0.898039) {
        pbrData.F0 = specularData.g;
    } else {
        pbrData.F0 = 0;
    }

    return pbrData;
}