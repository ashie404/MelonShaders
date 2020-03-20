#define SHADOWMAP_BIAS 0.9
#define LUT
#define INVERT_Y_LUT
#define TONEMAP_ACES
#define HDR
#define VIGNETTE
#define SCREENSPACE_REFLECTIONS
#define ICE_REFLECTIONS
#define SHADOW_Z_STRETCH 2.5

const int shadowMapResolution = 2048; //[1024 2048 4096 8192]
const int shadowDistance = 128; //[128 256 512 1024]
const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]
const float shadowMapBias = 0.85;
const int noiseTextureResolution = 256;