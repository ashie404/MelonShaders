const float pi = 3.1415926535897932384626433832795;

float ggx(vec3 normal, vec3 svec, PBRData pbrData) {
    float f0  = pbrData.F0;
    float roughness = pow(1.0 - pbrData.smoothness, 2.0);

    vec3 h      = lightVector - svec;
    float hn    = inversesqrt(dot(h, h));
    float hDotL = clamp01(dot(h, lightVector)*hn);
    float hDotN = clamp01(dot(h, normal)*hn);
    float nDotL = clamp01(dot(normal, lightVector));
    float denom = (hDotN * roughness - hDotN) * hDotN + 1.0;
    float D     = roughness / (pi * denom * denom);
    float F     = f0 + (1.0-f0) * exp2((-5.55473*hDotL-6.98316)*hDotL);
    float k2    = 0.25 * roughness;

    return nDotL * D * F / (hDotL * hDotL * (1.0-k2) + k2);
}