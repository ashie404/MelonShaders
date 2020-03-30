float calcSSS(in vec3 viewPos, in vec3 normal, in vec3 lightVec) {
    // very basic subsurface scattering 
    // just calculates how lighting would travel through a semi-translucent with no real "scattering"

    vec3 H = normalize(-lightVec + normal);
    float strength = pow(clamp01(dot(viewPos, -H)), 1);

    return strength;
}