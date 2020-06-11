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

// atmospheric scattering from wwwtyro https://github.com/wwwtyro/glsl-atmosphere

#define iSteps 8
#define jSteps 2

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    vec2 p = rsi(r0, r, rAtmos);
    if (p.x > p.y) return vec3(0,0,0);
    p.y = min(p.y, rsi(r0, r, rPlanet).x);
    float iStepSize = (p.y - p.x) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie);
}

vec3 getSkyColor(vec3 worldPos, vec3 viewVec, vec3 sunVec, vec3 moonVec, float angle) {
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    vec3 skyPos = worldPos;
    skyPos.y = max(skyPos.y, 0.0);

    vec3 skyColor = vec3(0.14, 0.2, 0.24)*0.025;

    if (night < 0.1) {
        skyColor = atmosphere(
            normalize(skyPos),           // normalized ray direction
            vec3(0,6372e3,0),               // ray origin
            sunVec,                        // position of the sun
            22.0,                           // intensity of the sun
            6371e3,                         // radius of the planet in meters
            6471e3,                         // radius of the atmosphere in meters
            vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
            21e-6,                          // Mie scattering coefficient
            8e3,                            // Rayleigh scale height
            1.2e3,                          // Mie scale height
            0.758                           // Mie preferred scattering direction
        );

        skyColor = 1.1 - exp(-1.0 * skyColor);
    } else if (night < 0.95) {
        vec3 oldC = skyColor;
        skyColor = atmosphere(
            normalize(skyPos),           // normalized ray direction
            vec3(0,6372e3,0),               // ray origin
            sunVec,                        // position of the sun
            22.0,                           // intensity of the sun
            6371e3,                         // radius of the planet in meters
            6471e3,                         // radius of the atmosphere in meters
            vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
            21e-6,                          // Mie scattering coefficient
            8e3,                            // Rayleigh scale height
            1.2e3,                          // Mie scale height
            0.758                           // Mie preferred scattering direction
        );

        skyColor = 1.1 - exp(-1.0 * skyColor);
        skyColor = mix(skyColor, oldC, night);
    }


    // draw clouds if y is greater than 0
    float cloudShape = 0.0;
    #ifdef CLOUDS
    if (worldPos.y >= 0) {
        float time = frameTimeCounter*CLOUD_SPEED/32;
        vec2 uv = (worldPos.xz / worldPos.y)/2;
        vec2 sunUv = (sunVec.xz / sunVec.y)/2;

        // set up 2D ray march variables
        vec2 marchDist = vec2(0.35 * max(viewWidth, viewHeight)) / vec2(viewWidth, viewHeight);
        float stepsInv = 1.0 / 3.0;
        vec2 sunDir = normalize(sunUv - uv) * marchDist * stepsInv;
        vec2 marchUv = uv;
        float cloudColor = 1.0;
        cloudShape = clouds(uv, time);

        #ifdef CLOUD_LIGHTING
        // 2D ray march lighting loop based on uncharted 4
        if (cloudShape >= 0.25) {
            for (float i = 0.0; i < marchDist.x; i += marchDist.x * stepsInv)
            {
                marchUv += sunDir * i;
   	        	float c = clouds(marchUv, time);
                cloudColor *= clamp(1.0 - c, 0.0, 1.0);
            }
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