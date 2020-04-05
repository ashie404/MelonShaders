#define PI 3.141592
#define iSteps 8
#define jSteps 1

#include "/lib/noise.glsl"

// atmospheric scattering shader by wwwtyro https://github.com/wwwtyro/glsl-atmosphere 

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
    if (p.x > p.y) return vec3(0.0);
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
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + (mu*mu));
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - (g*g)) * ((mu*mu) + 1.0)) / (pow(1.0 + (g*g) - 2.0 * mu * g, 1.5) * (2.0 + (g*g)));

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

        // Sample the secondary ray. (commented out because i only do 1 secondary sample for performance reasons)
        //for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        //}

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

vec3 _SunHaloColor = vec3(0.4900519, 0.5582597, 0.75735295);
float _SunHaloExponent = 25;
float _SunHaloContribution = 0.25;

vec3 _HorizonLineColor = vec3(0,0,0);
float _HorizonLineExponent = 4;
float _HorizonLineContribution = 0;

vec3 _SkyGradientTop =    vec3(0.1137255, 0.17647064, 0.26666668);
vec3 _SkyGradientBottom = vec3(0.3803922, 0.47450984, 0.6156863);
float _SkyGradientExponent = 2.5;


// less accurate but more stylized atmosphere function
vec3 stylizedAtmosphere(vec3 worldPos, vec3 sunPos) {
    // Masks.
    float maskHorizon = dot(normalize(worldPos), vec3(0, 1, 0));
    float maskSunDir = dot(normalize(worldPos), normalize(sunPos));
    // Sun halo.
    vec3 sunHaloColor = _SunHaloColor * _SunHaloContribution;
    float bellCurve = pow(clamp01(maskSunDir), _SunHaloExponent * clamp01(abs(maskHorizon)));
    float horizonSoften = 1 - pow(1 - clamp01(maskHorizon), 50);
    sunHaloColor *= clamp01(bellCurve * horizonSoften);
    // Horizon line.
    vec3 horizonLineColor = _HorizonLineColor * clamp01(pow(1 - abs(maskHorizon), _HorizonLineExponent));
    horizonLineColor = mix(vec3(0), horizonLineColor, _HorizonLineContribution);
    // Sky gradient.
    vec3 skyGradientColor = mix(_SkyGradientTop, _SkyGradientBottom, pow(1 - clamp01(maskHorizon), _SkyGradientExponent));
    vec3 finalColor = clamp01(sunHaloColor + horizonLineColor + skyGradientColor);
    return finalColor;
}

vec3 DrawStars(vec3 worldPos) {
    // get noise with multiplied world positon (so that the noise is small enough for stars)
    float noise = cellular(worldPos * 32);
    if (noise < 0.15) {
        return mix(vec3(1), NIGHT_SKY_COLOR, noise + 0.85);
    } else {
        return NIGHT_SKY_COLOR;
    }
    //return vec3(noise);
}

vec4 calculateSunSpot(vec3 viewVector, vec3 sunVector) {
    float cosTheta = dot(viewVector, sunVector);

    // limb darkening approximation
    const vec3 a = vec3(0.397, 0.503, 0.652);
    const vec3 halfa = a * 0.5;
    const vec3 normalizationConst = vec3(0.896, 0.873, 0.844);

    float sunAngularRadius = CELESTIAL_RADIUS / 10;

    float x = clamp(1.0 - ((sunAngularRadius * 0.6) - acos(cosTheta)) / (sunAngularRadius * 0.6), 0.0, 1.0);
    vec3 sunDisk = celestialTint * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;// * lightColors[0];

    //return cosTheta > cos(sunAngularRadius) ? sunDisk : background;
    return vec4(sunDisk, float(cosTheta > cos(sunAngularRadius)));
}

vec3 GetSkyColor(vec3 worldPos, vec3 sunPos, float isNight){
    vec3 skyPos = worldPos;
    // black void prevention
    if (skyPos.y < 0)
        skyPos.y = 0;

    vec3 color = atmosphere(
        normalize(skyPos),           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        sunPos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                  // Mie scale height
        0.758                           // Mie preferred scattering direction
    );

    //stylizedAtmosphere(worldPos, sunPos);

    // Apply exposure.
    color = 1.0 - exp(-1 * color);

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec3 viewPos = toNDC(screenPos.xyz);

    vec4 sunSpot = calculateSunSpot(normalize(worldPos), mat3(gbufferModelViewInverse) * normalize(lightVector));
    color = mix(color, sunSpot.rgb, sunSpot.r);

    // clouds

    #ifdef CLOUDS

    float time = frameTimeCounter * CLOUD_SPEED;

    float cloudBrightness = (CLOUD_DENSITY * 4) * (1.0-(isNight/1.05));
    float cumulusDensity = CUMULUS_DENSITY;
    if (rainStrength >= 0.01) {
        cumulusDensity = clamp01(CUMULUS_DENSITY / (1.0-rainStrength));
        cloudBrightness /= (1.0-rainStrength);
        cloudBrightness = clamp(cloudBrightness, 0, 4);
    }

    // cirrus clouds
    float density = smoothstep(1.0 - CIRRUS_DENSITY, 1.0, fbm(worldPos.xyz / worldPos.y * 2.0 + time * 0.05)) * 0.3;
    color = mix(color, vec3(1.0), cloudBrightness * density * max(worldPos.y, 0.0));

    // cumulus clouds

    // precompute position and time variable so it doesn't have to be recalculated every iteration
    vec3 posTime = worldPos.xyz / worldPos.y + time * 0.3;
    for (int i = 0; i < CUMULUS_LAYERS; i++)
    {
        float density = smoothstep(1.0 - cumulusDensity, 1.0, fbm((0.7 + float(i) * 0.01) * posTime));
        color = mix(color, vec3(cloudBrightness * density * 5.0), min(density, 1.0) * max(worldPos.y, 0.0));
    }
    
    #endif

    return color;
}