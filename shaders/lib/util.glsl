/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

// these are commented purely to prevent compile errors, however they do still set buffer formats
/*
const int colortex0Format = R11F_G11F_B10F; // Color buffer
*/

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