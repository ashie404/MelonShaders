/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

uniform float isSwamp;

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
//#define ACES_FAST // Uses a basic curve fit ACES function instead of the full-fat function. Disables all ACES configuration sliders, but should gain a large chunk of performance.

const int noiseTextureResolution = 512;
const float sunPathRotation = -40.0; // [-40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0]

// lighting settings
#define SSS // Subsurface scattering.
#define SSS_SCATTER 1.0 // Light scattering radius on subsurface scattering. [0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SPECULAR // Specular highlights.
#define SPEC_REFLECTIONS // Specular reflections. Has no effect if reflections are disabled.
#define DIRECTIONAL_LIGHTMAP
#define DIRECTIONAL_LIGHTMAP_STRENGTH 1.0 // Strength of directional lightmaps. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define LIGHTMAP_STRENGTH 1.0 // Strength of lightmap falloff. Fixes rooms that appear too dark/moody. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

// AO settings
#define RTAO // Ray-traced ambient occlusion.
//#define RTAO_DEBUG // Outputs the RTAO buffer directly to the screen.

#define RTAO_RAYS 2 // How many rays to shoot out per frame for RTAO. Higher will be less noisy, but laggier. [1 2 3 4 5 6 7 8]
#define RTAO_STEPS 8 // How many steps per RTAO ray. [4 5 6 7 8 9 10 11 12 13 14 15 16 24 32 48 64]

#define RTAO_FILTER // Whether to filter the RTAO or not. Helps RTAO be less noisy.

// shadow settings
#define RAIN_SOFTEN // Whether to soften shadows when raining or not.
#define PCSS // Percentage-closer soft shadowing. Makes shadows hard at the contact point, and softer farther away.
#define SHADOW_SOFTNESS 1.0 // Shadow softness. If PCSS is on, affects how quickly the shadows get soft. [0.25 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.25 2.5 2.75 3.0]
const int shadowMapResolution = 2048; // [1024 2048 4096 8192]
const int shadowDistance = 128; // [128 256 512 1024 2048 4096]

//#define PXL_SHADOWS // Pixelate shadows to world grid. gives a cool effect.
#define PXL_SHADOW_RES 16.0 // Resolution of pixelated shadows. [4.0 8.0 16.0 32.0 64.0 128.0]

// sky settings
#define STARS
#define FOG
#define FOG_DENSITY 0.3 // Density of fog. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define CUMULUS // 2D cumulus clouds
#define CLOUD_SPEED 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CLOUD_DENSITY 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CLOUD_LIGHTING

#define VL // Volumetric lighting.
#define VL_DENSITY 0.2 // Density of volumetric lighting. [0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.2 1.25 1.3 1.4 1.5 1.6 1.75 1.8 1.9 2.0]
#define VL_STEPS 4 // How many raymarching steps to take when calculating volumetric lighting. Higher is laggier, but will most likely look better. [4 6 8 12 16 24 32]
#define PATCHY_VL_FOG // adds noise to volumetric fog. wip

//#define SKYTEX // Whether to use the sky texture or atmosphere render. Requires Fabric Skyboxes mod if not using OptiFine.
#define SKYBOX_BRIGHT 2.0 // Brightness of skybox texture. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define SKYCLR_BRIGHT 0.5 // Brightness of minecraft sky color. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]

// visual settings
#define REFLECTIONS // Enables sky reflections. 
#define CLOUD_REFLECTIONS // Enables cloud reflections. Expensive but prettier.
#define SSR // Screenspace reflections. Has no effect if reflections are disabled.
#define MICROFACET_REFL // Whether to use microfacet distribution on rough reflections or not. When off, uses LODs for rough reflections. LOD rough reflections will look less noisy, and perform better, but may have more artifacting.
#define ROUGH_REFL_SAMPLES 2 // When microfacet rough reflections are enabled, this controls how many rays to shoot out per frame. Higher is laggier, but will be less noisy. [1 2 3 4 5 6 7 8]
#define REFL_FILTER // Whether to use a filter on rough reflections or not. Helps microfacet reflections be more accurate and less noisy, at the cost of some ghosting.
//#define REFL_DEBUG // Debug view for reflection filtering, outputs the raw filter buffer.
//#define WHITEWORLD // Removes albedo multiplication at end of shading function, causing the world to appear white, but still fully shaded.
#define NIGHT_DESAT // Whether to desaturate colors at night or not.
#define HEAT_DISTORT // Whether to have a heat distortion effect in nether or not. Does not work if DOF is enabled.

// translucent rendering settings
#define TRANS_MULT // Uses multiply blending for translucents instead of regular alpha blending. Could make certain mods/blocks behave weirdly.
#define FAKE_REFRACT // Whether to have (fake) translucent refraction or not.
#define REFRACT_STRENGTH 1.0 // Strength of translucent refraction. [0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.1 1.25 1.3 1.4 1.5]
#define BLUR_REFRACT // Whether to blur translucents or not. Has no effect if translucent refraction is off.

// rain effects
//#define RAIN_PUDDLES // When rainy, objects will appear more wet. Requires specular and reflections to be enabled to work. Can cause storms to be much laggier.
#define STRETCH_PUDDLES_Y // Whether to stretch puddles on the Y axis or not. Prevents circular puddle patterns from appearing on sides of blocks.
#define PUDDLE_MULT 1.0 // How much the puddles should cover terrain. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.25 3.5 3.75 4.0]
//#define POROSITY // Enables LabPBR porosity for resource packs that support it. Blue channel emissives have to be disabled for this to work. Rain puddles have to be enabled for this to work.

// water settings
#define ICE_NORMALS
#define WAVE_FOAM
#define WAVE_FOAM_FADE
#define WAVE_CAUSTICS // Renders a caustics-like pattern on the surface of the water.
#define WAVE_CAUSTICS_D 1.0 // Density of water patterns. [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WAVE_PIXEL
#define WAVE_PIXEL_R 16.0 // Resolution of water pattern pixelization. [4.0 8.0 16.0 32.0 64.0 128.0]
#define WAVE_SPEED 0.5 // Speed of water patterns. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define WAVE_BRIGHTNESS 1.0 // Brightness of wave foam and patterns. [0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define WAVE_NORMALS // Whether to have water normals or not.
#define WAVE_SCALE 0.1 // Scale of water normals. [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
//#define SNELLS_WINDOW // Whether to have the Snell's window phenomenon or not. Slightly broken, disabled by default.
#define UNDERWATER_WAVE_CAUSTICS // Renders caustic patterns under the water.

// post processing settings
#define BLOOM
#define BLOOM_STRENGTH 0.1 // Strength of bloom filter. [0.025 0.05 0.075 0.1 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6]

#define LUT // Color lookup table. Adjusts the overall look of colors.
#define LUTV 0 // [0 1 2 3 4 5]

// TAA settings

#define TAA // Temporal anti-aliasing. Helps smooth out jagged edges and reduce noise in noisy effects. Not recommended to turn off.
#define TAA_NCLAMP // TAA neighborhood clamping. Prevents ghosting. Not recommended to turn off.
#define TAA_BLEND 0.95 // How much to blend between current frame info and TAA history. Higher numbers will make the image smoother, but blurrier in motion. [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

// camera settings
//#define DOF
#define DOF_QUALITY 2 // Quality of depth of field. Higher quality is laggier. [1 2 4 8]  
#define APERTURE 1.0 // "Strength" of depth of field. [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]

#define CHROM_ABB

// tweaks
#define EMISSIVE_MAP 0 // Emissive map setting. [0 1 2]
#define EMISSIVE_STRENGTH 1.0 // Strength of emissives. [0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0 1.25 1.5 1.75 2.0 2.5 3.0 3.5 4.0 4.5 5.0 6.0 7.0 8.0 9.0 10.0]
#define EMISSIVE_FALLBACK // When emissive maps are on, and this setting is enabled, hardcoded emissives will also be calculated, and blended with emissive maps. Can fix missing emissives in certain resource packs.

#define WIND // Whether to have waving plants and leaves or not.
#define WIND_STRENGTH 1.0 // Strength of wind. [0.25 0.3 0.4 0.5 0.6 0.75 0.8 0.9 1.0 1.1 1.25 1.3 1.4 1.5 1.6 1.75 1.8 1.9 2.0]

#define WAVY_LAVA // Makes lava wavy.

#define REBUILD_Z // Whether to rebuild normal Z or not. Used for LabPBR 1.2+ resource packs. Disable if normal maps look wrong.
#define HARDCODED_METALS // Whether to have labPBR hardcoded metals enabled or not.

#define AMETHYST_BLOCK_GLOW 0 // Whether to have glowing amethyst blocks or not. [0 1]

#define BLOCKLIGHT_R 1.0 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_G 0.2 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_B 0.1 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define BLOCKLIGHT_I 1.0 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]

#define ENCHANT_R 0.6 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define ENCHANT_G 0.2 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define ENCHANT_B 1.0 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]
#define ENCHANT_I 0.5 // [0.0 0.1 0.2 0.25 0.3 0.4 0.5 0.6 0.7 0.75 0.8 0.9 1.0]

#define DEBUG 0 // [0 1 2 3 4 5 6 7 8]

// constant water coefficent values
vec3 waterCoeff = mix(vec3(0.8, 0.2, 0.1), vec3(1.0, 0.3, 0.3), isSwamp);
const vec3 waterScatterCoeff = vec3(1e-2);

const vec3 weatherColor = vec3(0.8, 0.7, 0.9);