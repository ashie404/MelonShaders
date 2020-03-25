// post processing settings
#define LUT // Color LUT. Makes some things look nicer, but can be too contrasty at times.
//#define INVERT_Y_LUT //Inverts your colors on the LUT. Has no effect if the LUT isn't enabled.
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

// ACES settings
#define TONEMAP_ACES // Whether to enable the ACES tonemap operator or not.
#define SAT_MOD                      0.5       
#define VIB_MOD                     -0.1        
#define CONT_MOD                     0.8         
#define CONT_MIDPOINT                0.3       
#define GAIN_MOD                     0.1         
#define LIFT_MOD                     0.0         
#define WHITE_BALANCE                6500        

#define Film_Slope                   0.50        
#define Film_Toe                     0.57        
#define Film_Shoulder                0.4         
#define Black_Clip                   0.0         
#define White_Clip                   0.045       
#define Blue_Correction              0.7     
#define Gamut_Expansion              1.5         

#define in_Match                     0.14        
#define Out_Match                    0.14

// non-user-settable
#define NIGHT_SKY_COLOR vec3(0.001, 0.004, 0.01)
const float shadowMapBias = 0.85;
const int noiseTextureResolution = 256;
const vec3 celestialTint = vec3(0.99, 0.99, 0.58);