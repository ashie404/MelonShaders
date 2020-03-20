vec3 getExposure(in vec3 color) {
    vec3 retColor;
    color *= 1.115;
    retColor = color;

    return retColor;
}

vec3 Reinhard(in vec3 color) {
    color = color/(1 + color);

    // return converted back to linear from gamma space
    return pow(color, vec3(1 / 2.2));
}