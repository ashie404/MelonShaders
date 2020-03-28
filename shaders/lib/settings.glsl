// post processing settings
#define LUT // Color LUT. Makes some things look nicer, but can be too contrasty at times.
//#define INVERT_Y_LUT //Inverts your colors on the LUT. Has no effect if the LUT isn't enabled.
#define VIGNETTE
#define BLOOM // Whether to apply a bloom filter or not.

// visual settings
#define SCREENSPACE_REFLECTIONS // Enables reflections.
//#define SPECULAR_REFLECTIONS // Enables screen space reflections on smooth surfaces. Has no effect if screenspace reflections or specular mapping is disabled. Not recommended if resource pack doesn't comply with LabPBR.
#define SPECULAR // Whether to enable specular highlight calculation or not. Not recommended if resource pack doesn't comply with LabPBR.
#define NORMAL_MAP // Whether to enable normal mapping or not. Not recommended if resource pack doesn't comply with LabPBR.
#define SSS // Subsurface scattering. Helps with semi-translucents like leaves and grass and makes them look better from behind.
#define SSS_STRENGTH 1 // Strength of subsurface scattering. [0 0.25 0.5 0.75 1 1.25 1.5 1.75 2]

// shadow settings
#define SHADOW_BIAS 0.020 //Increase this if you get shadow acne. Decrease this if you get peter panning. [0.000 0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.010 0.012 0.014 0.016 0.018 0.020 0.022 0.024 0.026 0.028 0.030 0.035 0.040 0.045 0.050]
const int shadowMapResolution = 2048; //[1024 2048 4096 8192]
const int shadowDistance = 128; //[128 256 512 1024]

// sky settings
#define CELESTIAL_RADIUS 0.75 // Radius of celestial bodies (sun and moon). [0.5 0.75 1.25 1.5]
const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

// ACES settings
#define TONEMAP_ACES // Whether to enable the ACES tonemap operator or not.
#define SAT_MOD                      0.15     // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define VIB_MOD                      0.1         // [-0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CONT_MOD                     0.1         // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CONT_MIDPOINT                0.0         // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GAIN_MOD                     0.0         // [-1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LIFT_MOD                     2.0         // [-10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define WHITE_BALANCE                7200        // [4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000 8100 8200 8300 8400 8500 8600 8700 8800 8900 9000 9100 9200 9300 9400 9500 9600 9700 9800 9900 10000 10100 10200 10300 10400 10500 10600 10700 10800 10900 11000 11100 11200 11300 11400 11500 11600 11700 11800 11900 12000]
#define NIGHT_DESATURATION 0.65 // Adjusts night desaturation. Not affected by ACES being off. [0 0.2 0.3 0.45 0.5 0.65 0.8 1]

#define Film_Slope                   0.60        //[0.0 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
#define Film_Toe                     0.35        //[0.00 0.05 0.15 0.25 0.35 0.45 0.55 0.65 0.75 0.85 0.95 1.05]
#define Film_Shoulder                0.25         //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.6 0.7 0.8 0.9 1.0]
#define Black_Clip                   0.0         //[0.0 0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 0.1]
#define White_Clip                   0.045       //[0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 1.0]
#define Blue_Correction              -0.2         //[0.0 -0.10 -0.20 -0.30 -0.40 -0.50 -0.60 -0.70 -0.80 -0.90 -1.0]
#define Gamut_Expansion              2.0         //[0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

#define in_Match                     0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]
#define Out_Match                    0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]

// misc
//#define WHITEWORLD // Returns white on albedo. Useful for debugging lighting.
//#define ISOMETRIC // Removes all perspective projection. Mainly for fun purposes, breaks most lighting effects.
#define WAVING_TERRAIN // Enables waving leaves, grass and other plants.

// non-user-settable
#define NIGHT_SKY_COLOR vec3(0.001, 0.004, 0.01)
const float shadowMapBias = 0.85;
const int noiseTextureResolution = 256;
const vec3 celestialTint = vec3(3, 3, 2.5);