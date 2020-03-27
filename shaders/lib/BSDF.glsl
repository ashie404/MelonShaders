const float PI = 3.1415926535897;

float OrenNayar(vec3 v, vec3 l, vec3 n, float r) {
    
    r *= r;
    
    float NdotL = dot(n,l);
    float NdotV = dot(n,v);
    
    float t = max(NdotL,NdotV);
    float g = max(.0, dot(v - n * NdotV, l - n * NdotL));
    float c = g/t - g*t;
    
    float a = .285 / (r+.57) + .5;
    float b = .45 * r / (r+.09);

    return max(0., NdotL) * ( b * c + a);

}

float ggx(vec3 normal, vec3 svec, PBRData pbrData) {
    float f0  = pbrData.F0;
    float roughness = pow(1.0 - pbrData.smoothness, 2.0);

    vec3 h      = lightVector - svec;
    float hn    = inversesqrt(dot(h, h));
    float hDotL = clamp01(dot(h, lightVector)*hn);
    float hDotN = clamp01(dot(h, normal)*hn);
    float nDotL = clamp01(dot(normal, lightVector));
    float denom = (hDotN * roughness - hDotN) * hDotN + 1.0;
    float D     = roughness / (PI * denom * denom);
    float F     = f0 + (1.0-f0) * exp2((-5.55473*hDotL-6.98316)*hDotL);
    float k2    = 0.25 * roughness;

    return nDotL * D * F / (hDotL * hDotL * (1.0-k2) + k2);
}

// unused V

vec3 distributeMicrofacets(vec3 normal, vec4 noise, float alpha2, vec2 pattern) {
    noise.xyz = normalize(cross(normal, noise.xyz * 2.0 - 1.0));
    return normalize(noise.xyz * sqrt(alpha2 * noise.w / (1.0 - noise.w * 0.9)) + normal);
}