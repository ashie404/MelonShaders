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

vec3 getAlbedo(in vec2 coord) {
    // return albedo in linear space
    return pow(texture2D(gcolor, coord).rgb, vec3(2.2));
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