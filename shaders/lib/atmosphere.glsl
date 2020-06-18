/*
    Melon Shaders by June
    https://j0sh.cf
*/

// sun spot calculation
vec4 calculateSunSpot(vec3 viewVector, vec3 sunVector, float radius, bool isMoon) {
    float cosTheta = dot(viewVector, sunVector);

    // limb darkening approximation
    const vec3 a = vec3(0.397, 0.503, 0.652);
    const vec3 halfa = a * 0.5;
    const vec3 normalizationConst = vec3(0.896, 0.873, 0.844);

    float sunAngularRadius = radius / 10;

    float x = clamp(1.0 - ((sunAngularRadius * 0.6) - acos(cosTheta)) / (sunAngularRadius * 0.6), 0.0, 1.0);
    vec3 sunDisk = vec3(0.0);
    if (!isMoon) sunDisk = (vec3(1.0, 0.99, 0.96)*5.0*8.0) * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;
    else sunDisk = (vec3(0.6, 0.6, 0.6)*0.15*8.0) * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;

    return vec4(sunDisk, float(cosTheta > cos(sunAngularRadius)));
}

float clouds(vec2 coord, float time)
{
    float coverage = hash12(vec2(coord.x * viewHeight/viewWidth, coord.y)) * 0.1 + clamp((CLOUD_COVERAGE*0.9) + rainStrength*2.0, 0.0, 2.0); // cloud coverage value

    float perlinFbm = perlinFbm(coord, 2.0, time);
    vec4 worleyFbmHighFreq = worleyFbm(coord, 4.0, time * 4.0, true);

    float finalClouds = remap(texture2D(noisetex, (coord/2.0) + (time/4.0)).g, 1.0 - coverage, 1.0, 0.0, 1.0) * coverage;
    finalClouds = remap(finalClouds, worleyFbmHighFreq.g * 0.45, 1.0, 0.0, 1.0);
    
    return max(0.0, finalClouds);
}

// atmospheric scattering from wwwtyro https://github.com/wwwtyro/glsl-atmosphere

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

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g, int iSteps, int jSteps) {
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

vec3 getSkyColor(vec3 worldPos, vec3 viewVec, vec3 sunVec, vec3 moonVec, float angle, bool atmosphereOnly) {
    float night = clamp01(((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03));
    float noon = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);

    vec3 skyPos = worldPos;
    if (atmosphereOnly) {
        skyPos.y = max(skyPos.y, 10.0);
    } else {
        skyPos.y = max(skyPos.y, 0.0);
    }

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
            30.2e-6,                          // Mie scattering coefficient
            8e3,                            // Rayleigh scale height
            1.2e3,                          // Mie scale height
            0.758,                           // Mie preferred scattering direction
            int(mix(16, 4, clamp01(noon))), // Primary raymarching steps
            int(mix(8,  2, clamp01(noon)))  // secondary raymarching steps
        );

        skyColor = 1.1 - exp(-1.0 * skyColor);
        vec3 W = vec3(0.2125, 0.7154, 0.0721);
        vec3 intensity = vec3(dot(skyColor, W));
        skyColor = mix(intensity, skyColor, 1.2);

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
            30.2e-6,                          // Mie scattering coefficient
            8e3,                            // Rayleigh scale height
            1.2e3,                          // Mie scale height
            0.758,                           // Mie preferred scattering direction
            int(mix(16, 4, clamp01(noon))), // Primary raymarching steps
            int(mix(8,  2, clamp01(noon)))  // secondary raymarching steps
        );

        skyColor = 1.1 - exp(-1.0 * skyColor);
        vec3 W = vec3(0.2125, 0.7154, 0.0721);
        vec3 intensity = vec3(dot(skyColor, W));
        skyColor = mix(intensity, skyColor, 1.2);

        skyColor = mix(skyColor, oldC, night);
    }

    float cloudShape = 0.0;

    if (!atmosphereOnly) {
        // draw clouds if y is greater than 0
        #ifdef CLOUDS
        if (worldPos.y >= 0) {
            float time = frameTimeCounter*CLOUD_SPEED/32;
            vec2 uv = (worldPos.xz / worldPos.y)/2;
            vec2 sunUv = (sunVec.xz / sunVec.y)/2;

            // set up 2D ray march variables
            vec2 marchDist = vec2(0.25 * max(viewWidth, viewHeight)) / vec2(viewWidth, viewHeight);
            float stepsInv = 1.0 / 4.0;
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
            cloudColor += clamp01(0.015-(night*0.0015)); // cloud "ambient" brightness
            // beer's law + powder sugar
            if (night > 0.25)
                cloudColor = exp(-cloudColor) * (1.0 - exp(-cloudColor*2.0)) * clamp(4.0/(night*4), 0.1, 1.0);
            else
                cloudColor = exp(-cloudColor) * (1.0 - exp(-cloudColor*2.0)) * 4.0;
            cloudColor *= cloudShape;

            skyColor = mix(skyColor, mix(skyColor, vec3(cloudColor)*max(lightColor, 0.1), clamp01(cloudShape)), clamp01(worldPos.y/48.0));
        }
        #endif

        skyColor += mix(vec3(0.0), mix(vec3(0.0), calculateSunSpot(viewVec, sunVec, CELESTIAL_RADIUS, false).rgb, clamp01(1.0-cloudShape)), clamp01(worldPos.y/64.0))*(skyColor*4.0);
        skyColor += mix(vec3(0.0), calculateSunSpot(viewVec, moonVec, CELESTIAL_RADIUS+0.1, true).rgb, clamp01(1.0-(cloudShape*2.0)));

        #ifdef STARS
        float starNoise = cellular(normalize(worldPos)*32);
        if (starNoise <= 0.05) {
            skyColor += mix(vec3(0.0), mix(vec3(0.0), mix(vec3(0.0), vec3(cellular(normalize(worldPos)*16.0)*4.0), clamp01(1.0-starNoise)), night), clamp01(1.0-(cloudShape*4.0)));
        }
        #endif
    }

    return skyColor;
}

void applyFog(in vec3 viewPos, in vec3 worldPos, in float depth0, inout vec3 color) {
    float depth = length(viewPos);
    if (isEyeInWater == 1) {
        // render underwater fog
        color *= exp(-vec3(1.0, 0.2, 0.1) * depth);
    } else if (isEyeInWater == 2) {
        // render lava fog
        color *= exp(-vec3(0.1, 0.2, 1.0) * (depth*4));
        color += vec3(0.2, 0.05, 0.0)*0.25;
    } 
    #ifdef FOG
    #ifndef NETHER
    else {
        // render regular fog
        if (depth0 != 1.0) {
            if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                vec3 atmosColor = getSkyColor(worldPos.xyz, normalize(worldPos.xyz), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, true);
                float fade = clamp01((eyeBrightnessSmooth.y-9)/55.0);
                color = mix(color, mix(vec3(0.05), atmosColor, fade), clamp01((depth/256.0)*FOG_DENSITY*mix(8.0, 1.0, fade)));
            } else if (eyeBrightnessSmooth.y <= 8) {
                color = mix(color, vec3(0.05), clamp01((depth/256.0)*FOG_DENSITY*8.0));
            } else {
                vec3 atmosColor = getSkyColor(worldPos.xyz, normalize(worldPos.xyz), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, true);
                color = mix(color, atmosColor, clamp01((depth/256.0)*FOG_DENSITY));
            }
        }
    }
    #else
    else {
        // render regular fog
        if (depth0 != 1.0) {
            color = mix(color, vec3(0.1, 0.02, 0.015)*0.5, clamp01((depth/256.0)*FOG_DENSITY*4.0));
        }
    }
    #endif
    #endif
}