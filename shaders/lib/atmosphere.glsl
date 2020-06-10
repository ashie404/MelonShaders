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
    vec3 sunDisk = (lightColor*8) * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;// * lightColors[0];

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

float clouds(vec2 coord, float time)
{
    float coverage = hash12(vec2(coord.x * viewHeight/viewWidth, coord.y)) * 0.1 + clamp(CLOUD_COVERAGE + rainStrength*2, 0.0, 2.0); // cloud coverage value

    // base noises
 	float perlinFbm = perlinFbm(coord, 2.0, time); // perlin fbm noise
    vec4 worleyFbmLowFreq = worleyFbm(coord, 2.0, time * 2.0, false); // low frequency worley without curl
    vec4 worleyFbmHighFreq = worleyFbm(coord, 8.0, time * 4.0, true); // high freq worley with curl

    // remapping of noise values
    float perlinWorley = remap(abs(perlinFbm * 2.0 - 1.0), 1.0 - worleyFbmLowFreq.r, 1.0, 0.0, 1.0);
    perlinWorley = remap(perlinWorley, 1.0 - coverage, 1.0, 0.0, 1.0) * coverage;

    float worleyLowFreq = worleyFbmLowFreq.g * 0.625 + worleyFbmLowFreq.b * 0.25 + worleyFbmLowFreq.a * 0.125;
    float worleyHighFreq = worleyFbmHighFreq.g * 0.625 + worleyFbmHighFreq.b * 0.25 + worleyFbmHighFreq.a * 0.125;

    // create final clouds by remapping previous noise values
    float finalClouds = remap(perlinWorley, worleyLowFreq - 1.0, 1.0, 0.0, 1.0);
    finalClouds = remap(finalClouds, worleyHighFreq * 0.2, 1.0, 0.0, 1.0);
    
    return max(0.0, finalClouds);
}

// basic gradient atmosphere

vec3 getSkyColor(vec3 worldPos, vec3 viewVec, vec3 sunVec, vec3 moonVec, float angle) {
    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    vec3 skyBSunrise = vec3(0.91, 0.36, 0.07);
    vec3 skyBTSunrise = vec3(0.17, 0.18, 0.29)*0.75;
    vec3 skyTSunrise = vec3(0.27, 0.28, 0.39);

    vec3 skyBNoon    = vec3(0.57, 0.6, 0.77);
    vec3 skyTNoon    = vec3(0.39, 0.51, 0.9);

    vec3 skyBSunset  = vec3(0.91, 0.36, 0.07);
    vec3 skyBTSunset = vec3(0.17, 0.18, 0.29)*0.75;
    vec3 skyTSunset  = vec3(0.27, 0.28, 0.39);

    vec3 skyBNight   = vec3(0.1, 0.15, 0.19)*0.025;
    vec3 skyTNight  = vec3(0.14, 0.2, 0.24)*0.025;

    vec3 skyBottom = (sunrise * skyBSunrise) + (noon * skyBNoon) + (sunset * skyBSunset) + (night * skyBNight);
    vec3 skyBottomNS = (sunrise * skyBTSunrise) + (noon * skyBNoon) + (sunset * skyBTSunset) + (night * skyBNight);
    vec3 skyTop = (sunrise * skyTSunrise) + (noon * skyTNoon) + (sunset * skyTSunset) + (night * skyTNight);

    vec3 skyColor = mix(skyBottom, skyTop, clamp01(worldPos.y*64));

    float sunHalo = 1.0-clamp01(calculateSunHalo(viewVec, sunVec, 16.0).r);
    skyColor = mix(skyColor, mix(skyBottomNS, skyTop, clamp01(worldPos.y*64)), sunHalo);

    // draw clouds if y is greater than 0
    float cloudShape = 0.0;
    #ifdef CLOUDS
    if (worldPos.y >= 0) {
        float time = frameTimeCounter*CLOUD_SPEED/32;
        vec2 uv = (worldPos.xz / worldPos.y)/2;
        vec2 sunUv = (sunVec.xz / sunVec.y)/2;

        // set up 2D ray march variables
        vec2 marchDist = vec2(max(viewWidth, viewHeight)) / vec2(viewWidth, viewHeight);
        float stepsInv = 1.0 / 3.0;
        vec2 sunDir = normalize(sunUv - uv) * marchDist * stepsInv;
        vec2 marchUv = uv;
        float cloudColor = 1.0;
        cloudShape = clouds(uv, time);

        #ifdef CLOUD_LIGHTING
        // 2D ray march lighting loop based on uncharted 4
        for (float i = 0.0; i < marchDist.x; i += marchDist.x * stepsInv)
        {
            marchUv += sunDir * i;
   	    	float c = clouds(marchUv, time);
            cloudColor *= clamp(1.0 - c, 0.0, 1.0);
        }
        #endif
        cloudColor += 0.05-(night*0.035); // cloud "ambient" brightness
        // beer's law + powder sugar
        if (night > 0.25)
            cloudColor = exp(-cloudColor) * (1.0 - exp(-cloudColor*2.0)) * (4.0/(night*4));
        else
            cloudColor = exp(-cloudColor) * (1.0 - exp(-cloudColor*2.0)) * 4.0;
        cloudColor *= cloudShape;
        
        skyColor = mix(skyColor, mix(skyColor, vec3(cloudColor)*lightColor, clamp01(cloudShape)), clamp01(worldPos.y*24));
    }
    #endif

    cloudShape *= 4;

    skyColor += mix(vec3(0.0), calculateSunSpot(viewVec, sunVec, CELESTIAL_RADIUS).rgb, clamp01(1.0-cloudShape));
    skyColor += mix(vec3(0.0), calculateSunSpot(viewVec, moonVec, CELESTIAL_RADIUS).rgb, clamp01(1.0-cloudShape));

    #ifdef STARS

    float starNoise = cellular(normalize(worldPos)*32);
    if (starNoise <= 0.05) {
        skyColor += mix(vec3(0.0), mix(vec3(0.0), mix(vec3(0.0), vec3(cellular(normalize(worldPos)*16)), clamp01(1.0-starNoise)), night), clamp01(1.0-cloudShape));
    }
    

    #endif

    return skyColor;
}