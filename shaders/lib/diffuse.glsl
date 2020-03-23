float Burley(vec3 V, vec3 L, vec3 N, float r) {
    r *= r;
    
    vec3 H = normalize(V + L);
    
    float NdotL = clamp(dot(N, L),0.,1.);
    float LdotH = clamp(dot(L, H),0.,1.);
    float NdotV = clamp(dot(N, V),0.,1.);

    float energyFactor = -r * .337748344 + 1.;
    float f90 = 2. * r * (LdotH*LdotH + .25) - 1.;

    float lightScatter =  f90 * pow(1.-NdotL,5.) + 1.;
    float viewScatter  =  f90 * pow(1.-NdotV,5.) + 1.;
    
    return NdotL * energyFactor * lightScatter * viewScatter;

}

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