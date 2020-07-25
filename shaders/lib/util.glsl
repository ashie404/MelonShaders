/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA16F;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex6Format = RGBA16F;
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

// poisson disk

const vec2 poissonDisk[64] = vec2[64](
vec2(-0.613392, 0.617481),
vec2(0.170019, -0.040254),
vec2(-0.299417, 0.791925),
vec2(0.645680, 0.493210),
vec2(-0.651784, 0.717887),
vec2(0.421003, 0.027070),
vec2(-0.817194, -0.271096),
vec2(-0.705374, -0.668203),
vec2(0.977050, -0.108615),
vec2(0.063326, 0.142369),
 vec2(0.203528, 0.214331),
 vec2(-0.667531, 0.326090),
 vec2(-0.098422, -0.295755),
 vec2(-0.885922, 0.215369),
 vec2(0.566637, 0.605213),
 vec2(0.039766, -0.396100),
 vec2(0.751946, 0.453352),
 vec2(0.078707, -0.715323),
 vec2(-0.075838, -0.529344),
 vec2(0.724479, -0.580798),
 vec2(0.222999, -0.215125),
 vec2(-0.467574, -0.405438),
 vec2(-0.248268, -0.814753),
 vec2(0.354411, -0.887570),
 vec2(0.175817, 0.382366),
 vec2(0.487472, -0.063082),
 vec2(-0.084078, 0.898312),
 vec2(0.488876, -0.783441),
 vec2(0.470016, 0.217933),
 vec2(-0.696890, -0.549791),
 vec2(-0.149693, 0.605762),
 vec2(0.034211, 0.979980),
 vec2(0.503098, -0.308878),
 vec2(-0.016205, -0.872921),
 vec2(0.385784, -0.393902),
 vec2(-0.146886, -0.859249),
 vec2(0.643361, 0.164098),
 vec2(0.634388, -0.049471),
 vec2(-0.688894, 0.007843),
 vec2(0.464034, -0.188818),
 vec2(-0.440840, 0.137486),
 vec2(0.364483, 0.511704),
 vec2(0.034028, 0.325968),
 vec2(0.099094, -0.308023),
 vec2(0.693960, -0.366253),
 vec2(0.678884, -0.204688),
 vec2(0.001801, 0.780328),
 vec2(0.145177, -0.898984),
 vec2(0.062655, -0.611866),
 vec2(0.315226, -0.604297),
 vec2(-0.780145, 0.486251),
 vec2(-0.371868, 0.882138),
 vec2(0.200476, 0.494430),
 vec2(-0.494552, -0.711051),
 vec2(0.612476, 0.705252),
 vec2(-0.578845, -0.768792),
 vec2(-0.772454, -0.090976),
 vec2(0.504440, 0.372295),
 vec2(0.155736, 0.065157),
 vec2(0.391522, 0.849605),
 vec2(-0.620106, -0.328104),
 vec2(0.789239, -0.419965),
 vec2(-0.545396, 0.538133),
 vec2(-0.178564, -0.596057)
);