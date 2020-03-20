const int RGBA = 0;
const int RGBA16 = 1;
const int RGB10_A2 = 1;

const int gcolorFormat = RGBA16;
const int gdepthFormat = RGBA;
const int gnormalFormat = RGBA16;
const int gaux2Format = RGB10_A2; //reflection image

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

#define GCOLOR_OUT gl_FragData[0]
#define GDEPTH_OUT gl_FragData[1]
#define GNORMAL_OUT gl_FragData[2]

vec3 getAlbedo(in vec2 coord) {
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