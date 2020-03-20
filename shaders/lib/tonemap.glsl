vec3 getExposure(in vec3 color) {
    vec3 retColor;
    color *= 1.115;
    retColor = color;

    return retColor;
}

vec3 Reinhard(in vec3 color) {
    color = color/(1 + color);

    // convert linear space back to gamma
    return pow(color, vec3(1 / 2.2));
}

vec3 tonemapACES( vec3 x )
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    vec3 color = (x*(a*x+b))/(x*(c*x+d)+e);

    // convert linear space back to gamma
    return pow(color, vec3(1 / 2.2));
}