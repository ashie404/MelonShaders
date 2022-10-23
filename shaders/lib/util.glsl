/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

// these are commented purely to prevent compile errors, however they do still set buffer formats
/*
const int colortex0Format = R11F_G11F_B10F; // Color buffer
const int colortex1Format = RGBA16; // Lightmaps, material mask, albedo alpha, specular map (gbuffers->final)
const int colortex2Format = R11F_G11F_B10F; // Atmosphere (deferred->composite1), bloom (composite2->final)
const int colortex3Format = R11F_G11F_B10F; // No translucents buffer (deferred1->final)
const int colortex4Format = RGBA16; // Normals (gbuffers->final)
const int colortex5Format = RGBA16F; // RTAO Buffer
const int colortex6Format = R11F_G11F_B10F; // TAA Buffer
const int colortex8Format = RGBA16F; // Reflection buffer (only used with reflection filter)
*/
const bool colortex6Clear = false;
const bool colortex8Clear = false;
#ifdef RTAO
const bool colortex5Clear = false;
#endif

const float eyeBrightnessSmoothHalflife = 4.0;

#define clamp01(p) (clamp(p, 0.0, 1.0))
#define log10(x) log(x) / log(10.0)

const float PI = 3.1415926535897;
const float rPI = 1.0 / PI;
const float rLOG2 = 1.0 / log(2.0);

const float PHI = (1.0 + sqrt(5.0)) / 2.0;

// Dithering functions
float bayer2(vec2 a){
    a = floor(a);
    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

#define bayer4(a)   (bayer2(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer8(a)   (bayer4(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer16(a)  (bayer8(  0.5 * (a)) * 0.25 + bayer2(a))
#define bayer32(a)  (bayer16( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer64(a)  (bayer32( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer128(a) (bayer64( 0.5 * (a)) * 0.25 + bayer2(a))
#define bayer256(a) (bayer128(0.5 * (a)) * 0.25 + bayer2(a))

//Modified from: iq's "Integer Hash - III" (https://www.shadertoy.com/view/4tXyWN)
//Faster than "full" xxHash and good quality
uint baseHash(uvec2 p)
{
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

vec3 hash32(uvec2 x)
{
    uint n = baseHash(x);
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3((rz >> 1) & uvec3(0x7fffffffU))/float(0x7fffffff);
}

float gold_noise(in vec2 xy, in float seed)
{
    return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}

// luma functions
float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

float remap(float val, float min1, float max1, float min2, float max2) {
  return min2 + (val - min1) * (max2 - min2) / (max1 - min1);
}

#ifndef ACES

vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

vec3 toSrgb(vec3 linear) {
    return mix(
        linear * 12.92,
        pow(linear, vec3(0.416666666667)) * 1.055 - 0.055, // 1.0 / 2.4 = ~0.416666666667
        step(0.0031308, linear)
    );
}

#endif

// light color
void calcLightingColor(in float angle, in float rain, in vec3 spos, in vec3 slpos, out vec3 ambient, out vec3 light, out vec4 times) {

    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    times = vec4(sunrise, noon, sunset, night);

    vec3 sunriseAmbColor = vec3(0.33, 0.28, 0.23)*0.4;
    vec3 noonAmbColor    = vec3(0.37, 0.39, 0.58)*0.65;
    vec3 sunsetAmbColor  = vec3(0.33, 0.28, 0.23)*0.4;
    vec3 nightAmbColor   = vec3(0.29, 0.31, 0.49)*0.13;

    vec3 sunriseLightColor = vec3(1.5, 0.5, 0.15)*2.0;
    vec3 noonLightColor    = vec3(1.0, 0.99, 0.96)*3.0;
    vec3 sunsetLightColor  = vec3(1.5, 0.5, 0.15)*2.0;
    vec3 nightLightColor   = vec3(0.6, 0.6, 1.2)*0.17;

    ambient = ((sunrise * sunriseAmbColor) + (noon * noonAmbColor) + (sunset * sunsetAmbColor)) + (night * nightAmbColor);

    if (all(equal(slpos, spos))) {
      light = ((sunrise * sunriseLightColor) + (noon * noonLightColor) + (sunset * sunsetLightColor) + (night * nightLightColor)) * clamp(1.0-rain, 0.1, 1.0);
    } else {
      light = nightLightColor*clamp(1.0-rain, 0.1, 1.0);
    }
}

// fresnel
float fresnel_schlick(in vec3 viewPos, in vec3 normal, in float F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - clamp01(dot(normal, reflect(normalize(viewPos), normal))), 5.0);
}

// phase functions

// Mie phase function
float miePhase(float x, float d, float scatter) {
    float g = exp2(d*-scatter);
    float g2 = g*g;
    return (1.0/4.0*PI)*((1.0-g2)/pow(1.0+g2-2.0*g*x,1.5));
}

// Encoding & Decoding functions

#ifdef FSH

// lightmap encoding/decoding
float encodeLightmaps(vec2 a){
    ivec2 bf = ivec2(a*255.);
    return float( bf.x|(bf.y<<8) ) / 65535.;
}

vec2 decodeLightmaps(float a){
    int bf = int(a*65535.);
    return vec2(bf%256, bf>>8) / 255.;
}

// color encoding/decoding
#define m vec3(31,63,31)
float encodeColor(vec3 a){
    a += (clamp01(bayer16(gl_FragCoord.xy))-.5) / m;
    a = clamp(a, 0., 1.);
    ivec3 b = ivec3(a*m);
    return float( b.r|(b.g<<5)|(b.b<<11) ) / 65535.;
}
#undef m
vec3 decodeColor(float a){
    int bf = int(a*65535.);
    return vec3(bf%32, (bf>>5)%64, bf>>11) / vec3(31,63,31);
}

#endif

float interleavedGradientNoise(vec2 position_screen)
{
  vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
  return fract(magic.z * fract(dot(position_screen, magic.xy)));
}

vec2 vogelDiskSample(int sampleIndex, int samplesCount, float phi)
{
  float r = sqrt(sampleIndex + 0.5) / sqrt(samplesCount);
  float theta = sampleIndex * 2.4 + phi;

  float sinTheta = sin(theta);
  float cosTheta = cos(theta);
  
  return vec2(r * cosTheta, r * sinTheta);
}

vec3 sphereMap(vec2 a) {
  float phi = a.y * 2.0 * PI;
  float cosTheta = 1.0 - a.x;
  float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

  return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}

float getShadowBias(vec3 viewPos, float angle) {
  float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
  float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
  return mix(0.00005, 0.005, clamp01((length(viewPos)/256.0)+clamp01(sunrise/6.0+sunset/6.0)));
}