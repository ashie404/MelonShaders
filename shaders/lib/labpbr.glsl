/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

struct PBRData {
    float smoothness;
    float F0;
    // todo: implement rest of labpbr spec lol
};

PBRData getPBRData(vec4 specularData) {
    PBRData pbrData;

    pbrData.smoothness = specularData.r;
    
    if (specularData.g <= 229/255) {
        pbrData.F0 = specularData.g;
    } else {
        pbrData.F0 = 0;
    }

    // todo: decode rest of labpbr spec

    return pbrData;
}