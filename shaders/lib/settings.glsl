/*
    Melon Shaders by June
    https://juniebyte.cf
*/

/* ACES settings */
#define SAT_MOD                      0.15     // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define VIB_MOD                      0.15         // [-0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CONT_MOD                     0.1         // [-1.0 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CONT_MIDPOINT                0.2         // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GAIN_MOD                     0.0         // [-1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LIFT_MOD                     0.0         // [-10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define WHITE_BALANCE                7200        // [4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000 8100 8200 8300 8400 8500 8600 8700 8800 8900 9000 9100 9200 9300 9400 9500 9600 9700 9800 9900 10000 10100 10200 10300 10400 10500 10600 10700 10800 10900 11000 11100 11200 11300 11400 11500 11600 11700 11800 11900 12000]

#define Film_Slope                   0.60        //[0.0 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
#define Film_Toe                     0.45        //[0.00 0.05 0.15 0.25 0.35 0.45 0.55 0.65 0.75 0.85 0.95 1.05]
#define Film_Shoulder                0.25         //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.6 0.7 0.8 0.9 1.0]
#define Black_Clip                   0.0         //[0.0 0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 0.1]
#define White_Clip                   0.045       //[0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 1.0]
#define Blue_Correction              1.0         //[1.0 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1 0.0 -0.1 -0.2 -0.3 -0.4 -0.5 -0.6 -0.7 -0.8 -0.9 -1.0]
#define Gamut_Expansion              3.0         //[0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

#define in_Match                     0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]
#define Out_Match                    0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]

#define COLOR_AP1 // Whether to use the AP1 color space or not. Makes colors look more natural.

// shadow settings
#define SHADOW_SOFTNESS 1.0 // How soft the shadows should be. Has no effect if PCSS is enabled. [0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0 10.0]
#define PCSS // Percentage-closer soft shadowing. Makes shadows hard at contact point, and softer further away.
#define SHADOW_BIAS 0.00025

// sky settings
#define CELESTIAL_RADIUS 0.25 // Radius of celestial bodies (the sun and moon). [ 0.1 0.25 0.3 0.4 0.5 0.6 0.7 ]
#define STARS // Whether to have stars at night or not.
#define FOG // Whether to have fog or not.
#define FOG_DENSITY 1.0 // Density of fog. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.25 2.5 2.75 3.0 3.25 3.5]

// volumetrics
#define VL // Whether to have volumetric lighting or not. Does not work if fog is turned off.
#define VL_STEPS 8 // Volumetric lighting steps. Higher is much laggier. [4 8 16 24 32 48 64]
#define VL_DENSITY 1.0 // Density of VL fog. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define VARYING_VL_DENSITY

// cloud settings
#define CUMULUS // Whether to have cumulus clouds or not.
#define CIRRUS // Whether to have cirrus clouds or not.
#define CLOUD_SPEED 0.3 // How fast clouds move. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CLOUD_LIGHTING // Turns on and off cloud lighting. Can be very intensive. If your game lags badly when looking at the sky or a reflective surface like water, turn off.
#define CLOUD_COVERAGE 1.0 // Coverage of clouds in sky. [0.5 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2]

// lighting settings
#define SPECULAR // Specular highlights & reflections. Not recommended to have enabled unless your resourcepack is LabPBR compliant.
#define SSR // Screenspace reflections.
//#define HQ_REFLECTIONS // Makes screenspace reflections higher quality at the cost of performance.
#define SPECULAR_REFLECTION_STRENGTH 1.0 // Strength of specular reflections. [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define SSS // Subsurface scattering. Improves lighting vastly on leaves, grass, and flowers.
#define SSS_STRENGTH 1.0 // Strength of subsurface scattering. [0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.2 1.25 1.3 1.4 1.5 1.6 1.7 1.75 1.8 1.9 2]
#define DIRECTIONAL_LIGHTMAP // Whether to have blocklights and skylight affected by normal maps or not.
#define DIRECTIONAL_LIGHTMAP_STRENGTH 1.0 // Strength of directional lightmaps. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

// post processing settings
#define BLOOM
#define BLOOM_STRENGTH 0.1 // Strength of bloom. [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define LUT // Color lookup table. Adjusts the overall look of colors.
#define LUTV 0 // Which color LUT to use. Certain LUTs might require adjustments to film slope in ACES settings to not be over-contrasty. Night City Punk LUT created by shortnamesalex. [0 1 2 3 4]
#define TAA

// camera settings
#define DOF // Depth of field.
#define DOF_QUALITY 2 // Quality of the depth of field. Higher is laggier, but will look better. [1 2 3 4]
#define APERTURE 1.0 // The aperture of the camera. Determines how big the depth of field is. [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CHROM_ABB // Whether to have chromatic aberration in out-of-focus areas or not. Has no effect if DOF is off.

// tweaks

// blocklight color
#define BLOCKLIGHT_R 1.0 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_G 0.4 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_B 0.1 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_I 1.0 // Intensity of blocklight. [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]

#define EMISSIVE_MAP 0 // Emissive map setting. [0 1 2]
#define EMISSIVE_MAP_STRENGTH 1.0 // Strength of emissive maps. [0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0 10.0]

#define WIND // Whether to have waving terrain (leaves, plants) or not.
#define WIND_STRENGTH 1.0 // Strength of wind. [0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define NIGHT_DESAT // Whether to desaturate dark colors at night.

//#define WHITEWORLD

// water visual settings
#define WAVE_FOAM // Whether to have water foam or not.
#define WAVE_LINES // Whether to have water lines pattern on the water or not.
//#define WAVE_CAUSTICS // Whether to have a water caustics pattern on the water or not.
#define WAVE_PIXEL // Whether to snap the water patterns to a pixel grid or not.
#define WAVE_PIXEL_R 16.0 // Resolution of the pixel grid that water patterns are snapped to. [4.0 8.0 16.0 32.0 64.0 128.0]
#define WAVE_SPEED 0.5 // Speed of water patterns. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// translucents

//#define TRANS_REFRACTION // Whether to have (fake) translucent refraction or not.
#define REFRACTION_STRENGTH 1.0 // Strength of translucent refraction. [0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.25 1.3 1.4 1.5 1.6 1.75 1.8 1.9 2.0]
//#define BLUR_TRANSLUCENT // Whether to blur translucents or not. Has no effect if translucent refraction is off.
//#define TRANS_COMPAT // Translucents compatibility mode. Changes the blending method of translucents from multiplication to mix. Fixes some mods/resource packs that use translucents.

// debug

#define DEBUG_MODE 0 // [0 1 2 3 4]

const int noiseTextureResolution = 512;
const int shadowMapResolution = 2048; //[1024 2048 4096 8192]
const int shadowDistance = 128; //[128 256 512 1024]
const float shadowIntervalSize = 0.1;
const float sunPathRotation = -30.0; // [-40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0]

const vec3 nightSkyColor = vec3(0.14, 0.2, 0.24)*0.0005;