/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA32F;
*/

#define clamp01(p) (clamp(p, 0.0, 1.0))
#define log10(x) log(x) / log(10.0)

const float PI = 3.1415926535897;

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