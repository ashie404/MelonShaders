const int RGBA = 0;
const int RGBA16 = 1;
const int RGBA16F = 5;

const int gcolorFormat = RGBA16F;
const int gdepthFormat = RGBA;
const int gnormalFormat = RGBA16;

const bool gaux2MipmapEnabled = true;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

vec3 srgbToLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

vec3 getAlbedo(in vec2 coord) {
    // return albedo in linear space
    #ifndef WHITEWORLD
    return srgbToLinear(texture2D(gcolor, coord).rgb);
    #else
    return vec3(1);
    #endif
}

vec3 getNormal(in vec2 coord) {
    return texture2D(gnormal, coord).rgb * 2.0 - 1.0;
}

float getEmission(in vec2 coord) {
    return texture2D(gdepth, coord).a;
}

float getBlockLightStrength(in vec2 coord) {
    return texture2D(gdepth, coord).r;
}

float getSkyLightStrength(in vec2 coord) {
    return texture2D(gdepth, coord).g;
}