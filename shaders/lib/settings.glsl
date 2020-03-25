// post processing settings
#define LUT // Color LUT. Makes some things look nicer, but can be too contrasty at times.
//#define INVERT_Y_LUT //Inverts your colors on the LUT. Has no effect if the LUT isn't enabled.
#define TONEMAP_ACES // Rough ACES tonemapping curve.
#define VIGNETTE
#define BLOOM // Whether to apply a bloom filter or not.

// lighting settings
#define SCREENSPACE_REFLECTIONS // Enables reflections.
#define SPECULAR // Whether to enable specular highlight calculation or not. Not recommended if resource pack doesn't comply with LabPBR.
const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

// shadow settings
#define SHADOW_BIAS 0.020 //Increase this if you get shadow acne. Decrease this if you get peter panning. [0.000 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010 0.012 0.014 0.016 0.018 0.020 0.022 0.024 0.026 0.028 0.030 0.035 0.040 0.045 0.050]
const int shadowMapResolution = 2048; //[1024 2048 4096 8192]
const int shadowDistance = 128; //[128 256 512 1024]

// ungrouped
#define CELESTIAL_RADIUS 0.75 // Radius of celestial bodies (sun and moon). [0.5 0.75 1.25 1.5]

// non-user-settable
#define NIGHT_SKY_COLOR vec3(0.001, 0.004, 0.01)
const float shadowMapBias = 0.85;
const int noiseTextureResolution = 256;
const vec3 celestialTint = vec3(0.99, 0.99, 0.58);