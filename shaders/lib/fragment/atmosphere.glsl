// begin atmosphere code by robobo1221 ( from https://github.com/robobo1221/robobo1221Shaders )

//Sky coefficients and heights

const float airNumberDensity = 2.5035422e25; // m^3
const float ozoneConcentrationPeak = 8e-6;
const float ozoneNumberDensity = airNumberDensity * exp(-35.0e3 / 8.0e3) * ozoneConcentrationPeak;
const vec3 ozoneCrossSection = vec3(4.51103766177301E-21, 3.2854797958699E-21, 1.96774621921165E-22) * 0.0001; // cm^2 | single-wavelength values.

const float sky_planetRadius = 6731e3;

const float sky_atmosphereHeight = 110e3;
const vec2 sky_scaleHeights = vec2(8.0e3, 1.2e3);

const float sky_mieg = 0.80;

const vec3 sky_coefficientRayleigh = vec3(5.8000e-6, 1.3500e-5, 3.3100e-5);
const vec3 sky_coefficientMie = vec3(8.0000e-6, 8.0000e-6, 8.0000e-6); // Should be >= 2e-6
const vec3 sky_coefficientOzone = ozoneCrossSection * ozoneNumberDensity; // ozone cross section * (ozone number density * (cm ^ 3))

const vec2 sky_inverseScaleHeights = 1.0 / sky_scaleHeights;
const vec2 sky_scaledPlanetRadius = sky_planetRadius * sky_inverseScaleHeights;
const float sky_atmosphereRadius = sky_planetRadius + sky_atmosphereHeight;
const float sky_atmosphereRadiusSquared = sky_atmosphereRadius * sky_atmosphereRadius;

const mat2x3 sky_coefficientsScattering = mat2x3(sky_coefficientRayleigh, sky_coefficientMie);
const mat3   sky_coefficientsAttenuation = mat3(sky_coefficientRayleigh, sky_coefficientMie * 1.11, sky_coefficientOzone); // commonly called the extinction coefficient

vec2 rsi(vec3 position, vec3 direction, float radius) {
	float PoD = dot(position, direction);
	float radiusSquared = radius * radius;

	float delta = PoD * PoD + radiusSquared - dot(position, position);
	if (delta < 0.0) return vec2(-1.0);
	      delta = sqrt(delta);

	return -PoD + vec2(-delta, delta);
}

float sky_rayleighPhase(float cosTheta) {
	const vec2 mul_add = vec2(0.1, 0.28) * rPI;
	return cosTheta * mul_add.x + mul_add.y; // optimized version from [Elek09], divided by 4 pi for energy conservation
}

float sky_miePhase(float cosTheta, const float g) {
	float gg = g * g;
	return (gg * -0.25 + 0.25) * rPI * pow(-2.0 * (g * cosTheta) + (gg + 1.0), -1.5);
}

vec2 sky_phase(float cosTheta, const float g) {
	return vec2(sky_rayleighPhase(cosTheta), sky_miePhase(cosTheta, g));
}

vec3 sky_density(float centerDistance) {
	vec2 rayleighMie = exp(centerDistance * -sky_inverseScaleHeights + sky_scaledPlanetRadius);

	// Ozone distribution curve by Sergeant Sarcasm - https://www.desmos.com/calculator/j0wozszdwa
	float ozone = exp(-max(0.0, (35000.0 - centerDistance) - sky_planetRadius) * (1.0 / 5000.0))
	            * exp(-max(0.0, (centerDistance - 35000.0) - sky_planetRadius) * (1.0 / 15000.0));
	return vec3(rayleighMie, ozone);
}

vec3 sky_airmass(vec3 position, vec3 direction, float rayLength, const float steps) {
	float stepSize  = rayLength * (1.0 / steps);
	vec3  increment = direction * stepSize;
	position += increment * 0.5;

	vec3 airmass = vec3(0.0);
	for (int i = 0; i < steps; ++i, position += increment) {
		airmass += sky_density(length(position));
	}

	return airmass * stepSize;
}
vec3 sky_airmass(vec3 position, vec3 direction, const float steps) {
	float rayLength = dot(position, direction);
	      rayLength = rayLength * rayLength + sky_atmosphereRadiusSquared - dot(position, position);
		  if (rayLength < 0.0) return vec3(0.0);
	      rayLength = sqrt(rayLength) - dot(position, direction);

	return sky_airmass(position, direction, rayLength, steps);
}

vec3 sky_opticalDepth(vec3 position, vec3 direction, float rayLength, const float steps) {
	return sky_coefficientsAttenuation * sky_airmass(position, direction, rayLength, steps);
}
vec3 sky_opticalDepth(vec3 position, vec3 direction, const float steps) {
	return sky_coefficientsAttenuation * sky_airmass(position, direction, steps);
}

vec3 sky_transmittance(vec3 position, vec3 direction, const float steps) {
	return exp2(-sky_opticalDepth(position, direction, steps) * rLOG2);
}

vec3 calculateAtmosphere(vec3 background, vec3 viewVector, vec3 upVector, vec3 sunVector, vec3 moonVector, out vec2 pid, out vec3 transmittance, const int iSteps) {
	const int jSteps = 3;

	vec3 viewPosition = (sky_planetRadius + eyeAltitude) * upVector;

	vec2 aid = rsi(viewPosition, viewVector, sky_atmosphereRadius);
	if (aid.y < 0.0) {transmittance = vec3(1.0); return background;}
	
	pid = rsi(viewPosition, viewVector, sky_planetRadius * 0.9994);
	bool planetIntersected = pid.y >= 0.0;

	vec2 sd = vec2((planetIntersected && pid.x < 0.0) ? pid.y : max(aid.x, 0.0), (planetIntersected && pid.x > 0.0) ? pid.x : aid.y);

	float stepSize  = (sd.y - sd.x) * (1.0 / iSteps);
	vec3  increment = viewVector * stepSize;
	vec3  position  = viewVector * sd.x + (increment * 0.3 + viewPosition);

	vec2 phaseSun  = sky_phase(dot(viewVector, sunVector ), sky_mieg);
	vec2 phaseMoon = sky_phase(dot(viewVector, moonVector), sky_mieg);

	vec3 scatteringSun     = vec3(0.0);
	vec3 scatteringMoon    = vec3(0.0);
    vec3 scatteringAmbient = vec3(0.0);
	transmittance = vec3(1.0);

	for (int i = 0; i < iSteps; ++i, position += increment) {
		vec3 density          = sky_density(length(position));
		if (density.y > 1e35) break;
		vec3 stepAirmass      = density * stepSize;
		vec3 stepOpticalDepth = sky_coefficientsAttenuation * stepAirmass;

		vec3 stepTransmittance       = exp2(-stepOpticalDepth * rLOG2);
		vec3 stepTransmittedFraction = clamp01((stepTransmittance - 1.0) / -stepOpticalDepth);
		vec3 stepScatteringVisible   = transmittance * stepTransmittedFraction;

		scatteringSun  += sky_coefficientsScattering * (stepAirmass.xy * phaseSun ) * stepScatteringVisible * sky_transmittance(position, sunVector,  jSteps);
		scatteringMoon += sky_coefficientsScattering * (stepAirmass.xy * phaseMoon) * stepScatteringVisible * sky_transmittance(position, moonVector, jSteps);

        // Nice way to fake multiple scattering.
		scatteringAmbient += sky_coefficientsScattering * stepAirmass.xy * stepScatteringVisible;

		transmittance *= stepTransmittance;
	}

	vec3 scattering = scatteringSun * (vec3(1.0, 0.99, 0.96)*250.0) + scatteringMoon * vec3(0.15, 0.15, 0.15);

	transmittance = planetIntersected ? vec3(0.0) : transmittance;

	return background * transmittance + scattering;
}

// end atmosphere code by robobo1221

// sun & moon spot calculation
vec4 calculateSunSpot(vec3 viewVector, vec3 sunVector, float radius) {
    float cosTheta = dot(viewVector, sunVector);

    // limb darkening approximation
    const vec3 a = vec3(0.397, 0.503, 0.652);
    const vec3 halfa = a * 0.5;
    const vec3 normalizationConst = vec3(0.896, 0.873, 0.844);

    float sunAngularRadius = radius / 10;

    float x = clamp(1.0 - ((sunAngularRadius * 0.6) - acos(cosTheta)) / (sunAngularRadius * 0.6), 0.0, 1.0);
    vec3 sunDisk = vec3(0.0);
    sunDisk = (lightColor*100.0) * exp2(log2(-x * x + 1.0) * halfa) / normalizationConst;

    return vec4(sunDisk, float(cosTheta > cos(sunAngularRadius)));
}

vec4 calculateMoonSpot(vec3 viewVector, vec3 moonVector, float radius) {
    float cosTheta = dot(viewVector, moonVector);

    float moonAngularRadius = radius / 10;

    float x = clamp(1.0 - ((moonAngularRadius * 0.6) - acos(cosTheta)) / (moonAngularRadius * 0.6), 0.0, 1.0);
    vec3 moonDisk = vec3(0.0);
    moonDisk = (vec3(0.15, 0.15, 0.15)*25.0) * exp2(log2(-x * x + 1.0));

    return vec4(moonDisk, float(cosTheta > cos(moonAngularRadius)));
}

vec3 getSkyColor(vec3 viewPos, int atmosSteps) {
    vec3 skyColor = vec3(0.05, 0.1, 0.2);

    vec2 pid = vec2(0.0);
    vec3 skyTransmittance = vec3(0.0);

    skyColor = calculateAtmosphere(skyColor, normalize(viewPos), normalize(upPosition), normalize(sunPosition), normalize(moonPosition), pid, skyTransmittance, atmosSteps);

    skyColor = 1.0 - exp(-0.05 * skyColor);

    return skyColor;
}

void calculateCelestialBodies(in vec3 viewPos, in vec3 worldPos, inout vec3 color) {
	#if WORLD == 0

    #ifdef STARS
    float starNoise = cellular(normalize(worldPos.xyz)*32.0);
    if (starNoise <= 0.05) {
        color += mix(vec3(0.0), mix(vec3(0.0), vec3(cellular(normalize(worldPos.xyz)*16.0)), clamp01(1.0-starNoise)), clamp01(times.w))*4.0;
    }
    #endif

    vec4 sunSpot = calculateSunSpot(normalize(viewPos.xyz), normalize(sunPosition), 0.35);
    vec4 moonSpot = calculateMoonSpot(normalize(viewPos.xyz), normalize(moonPosition), 0.5);

    // add sun and moon spots
    color += sunSpot.rgb*color;
    color += moonSpot.rgb;
	
	#endif
}