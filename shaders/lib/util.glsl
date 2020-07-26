/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

/*
const int colortex0Format = R11F_G11F_B10F; // Color buffer
const int colortex1Format = RGBA32F; // Lightmaps, material mask, albedo alpha, specular map (gbuffers->final)
const int colortex2Format = R11F_G11F_B10F; // Atmosphere (deferred->composite1), bloom (composite2->final)
const int colortex3Format = R11F_G11F_B10F; // No translucents buffer (deferred1->final)
const int colortex4Format = RGB16F; // Normals (gbuffers->final)
const int colortex6Format = R11F_G11F_B10F; // TAA Buffer
const bool colortex6Clear = false;
const float eyeBrightnessSmoothHalflife = 4.0;
*/

#define clamp01(p) (clamp(p, 0.0, 1.0))
#define log10(x) log(x) / log(10.0)

const float PI = 3.1415926535897;
const float rPI = 1.0 / PI;
const float rLOG2 = 1.0 / log(2.0);

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

// luma functions
float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

// light color
void calcLightingColor(in float angle, in float rain, in vec3 spos, in vec3 slpos, out vec3 ambient, out vec3 light, out vec4 times) {

    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    times = vec4(sunrise, noon, sunset, night);

    vec3 sunriseAmbColor = vec3(0.33, 0.28, 0.23)*0.35;
    vec3 noonAmbColor    = vec3(0.37, 0.39, 0.58)*0.65;
    vec3 sunsetAmbColor  = vec3(0.33, 0.28, 0.23)*0.35;
    vec3 nightAmbColor   = vec3(0.19, 0.21, 0.29)*0.035;

    vec3 sunriseLightColor = vec3(1.5, 0.3, 0.15)*1.5;
    vec3 noonLightColor    = vec3(1.0, 0.99, 0.96)*3.0;
    vec3 sunsetLightColor  = vec3(1.5, 0.3, 0.15)*1.5;
    vec3 nightLightColor   = vec3(0.6, 0.6, 0.6)*0.05;

    ambient = ((sunrise * sunriseAmbColor) + (noon * noonAmbColor) + (sunset * sunsetAmbColor)) + (night * nightAmbColor);

    if (all(equal(slpos, spos))) {
      light = ((sunrise * sunriseLightColor) + (noon * noonLightColor) + (sunset * sunsetLightColor) + (night * nightLightColor)) * clamp(1.0-rain, 0.1, 1.0);
    } else {
      light = nightLightColor*clamp(1.0-rain, 0.1, 1.0);
    }
}

// fresnel
float fresnel(float bias, float scale, float power, vec3 I, vec3 N)
{
    return bias + scale * pow(1.0 + dot(I, N), power);
}

// Encoding & Decoding functions

#ifdef FSH

float encodeNormals(vec3 a) {
    vec2 spheremap = a.xy / sqrt( a.z * 8.0 + 8.0 ) + 0.5;
    ivec2 bf = ivec2(spheremap*255.0);
    return float( bf.x|(bf.y<<8) ) / 65535.0;
}

vec3 decodeNormals(float a) {
    int bf = int(a*65535.0);
    vec2 b = vec2(bf%256, bf>>8) / 63.75 - 2.0;
    float c = dot(b, b);
    return vec3( b * sqrt(1.0-c*0.25), 1.0 - c * 0.5 );
}

float encodeLightmaps(vec2 a) {
    ivec2 bf = ivec2(a*255.0);
    return float( bf.x|(bf.y<<8) ) / 65535.0;
}

vec2 decodeLightmaps(float a) {
    int bf = int(a*65535.0);
    return vec2(bf%256, bf>>8) / 255.0;
}

const vec3 bits = vec3( 5, 6, 5 );
const vec3 values = exp2( bits );
const vec3 rvalues = 1.0 / values;
const vec3 maxValues = values - 1.0;
const vec3 rmaxValues = 1.0 / maxValues;
const vec3 positions = vec3( 1.0, values.x, values.x*values.y );
const vec3 rpositions = 65535.0 / positions;

// specular encoding/decoding

float encodeSpecular(vec3 a) {
    a += (clamp01(bayer4(gl_FragCoord.xy))-0.5) / maxValues;
    a = clamp(a, 0.0, 1.0);
    return dot( round( a * maxValues ), positions ) / 65535.0;
}

vec3 decodeSpecular(float a) {
    return mod( a * rpositions, values ) * rmaxValues;
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

float getShadowBias(vec3 viewPos) {
    return mix(0.0001, 0.00035, clamp01(length(viewPos)/16.0));
}