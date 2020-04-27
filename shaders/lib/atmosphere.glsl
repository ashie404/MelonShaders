/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

// sun spot calculation
vec4 calculateSunSpot(vec3 viewVector, vec3 sunVector, float radius) {
    float cosTheta = dot(viewVector, sunVector);

    // limb darkening approximation
    const vec3 a = vec3(0.397, 0.503, 0.652);
    const vec3 halfa = a * 0.5;
    const vec3 normalizationConst = vec3(0.896, 0.873, 0.844);

    float sunAngularRadius = radius / 10;

    float x = clamp(1.0 - ((sunAngularRadius * 0.6) - acos(cosTheta)) / (sunAngularRadius * 0.6), 0.0, 1.0);
    vec3 sunDisk = lightColor * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;// * lightColors[0];

    //return cosTheta > cos(sunAngularRadius) ? sunDisk : background;
    return vec4(sunDisk, float(cosTheta > cos(sunAngularRadius)));
}

vec4 calculateSunHalo(vec3 viewVector, vec3 sunVector, float radius) {
    float cosTheta = dot(viewVector, sunVector);

    // limb darkening approximation
    const vec3 a = vec3(0.397, 0.503, 0.652);
    const vec3 halfa = a * 7.5;
    const vec3 normalizationConst = vec3(0.896, 0.873, 0.844);

    float sunAngularRadius = radius / 10;

    float x = clamp(1.0 - ((sunAngularRadius * 0.6) - acos(cosTheta)) / (sunAngularRadius * 0.6), 0.0, 1.0);
    vec3 sunDisk = lightColor * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;// * lightColors[0];

    //return cosTheta > cos(sunAngularRadius) ? sunDisk : background;
    return vec4(sunDisk, float(cosTheta > cos(sunAngularRadius)));
}

// basic gradient atmosphere

vec3 getSkyColor(vec3 worldPos, vec3 viewVec, vec3 sunVec, float angle) {
    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    vec3 skyBSunrise = vec3(0.91, 0.36, 0.07);
    vec3 skyTSunrise = vec3(0.27, 0.28, 0.39);

    vec3 skyBNoon    = vec3(0.57, 0.6, 0.77);
    vec3 skyTNoon    = vec3(0.39, 0.51, 0.9);

    vec3 skyBSunset  = vec3(0.91, 0.36, 0.07);
    vec3 skyTSunset  = vec3(0.27, 0.28, 0.39);

    vec3 skyBNight   = vec3(0.1, 0.15, 0.19)*0.025;
    vec3 skyTNight  = vec3(0.14, 0.2, 0.24)*0.025;

    vec3 skyBottom = (sunrise * skyBSunrise) + (noon * skyBNoon) + (sunset * skyBSunset) + (night * skyBNight);
    vec3 skyTop = (sunrise * skyTSunrise) + (noon * skyTNoon) + (sunset * skyTSunset) + (night * skyTNight);

    vec3 skyColor = mix(skyBottom, skyTop, clamp01(worldPos.y*64));

    float sunHalo = 1.0-clamp01(calculateSunHalo(viewVec, sunVec, 16.0).r);
    skyColor = mix(skyColor, skyTop, sunHalo);

    skyColor += calculateSunSpot(viewVec, sunVec, CELESTIAL_RADIUS).rgb;

    return skyColor;
}