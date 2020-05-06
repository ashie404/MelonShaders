/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex4Format = RGBA16F;
*/

#define clamp01(p) (clamp(p, 0.0, 1.0))
#define log10(x) log(x) / log(10.0)

uniform float screenBrightness;
const float PI = 3.1415926535897;

void calcLightingColor(in float angle, in float rain, out vec3 ambient, out vec3 light) {

    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    vec3 sunriseAmbColor = vec3(0.44, 0.22, 0.03)*0.5;
    vec3 noonAmbColor    = vec3(0.37, 0.39, 0.48)*0.5;
    vec3 sunsetAmbColor  = vec3(0.44, 0.22, 0.03)*0.5;
    vec3 nightAmbColor   = vec3(0.19, 0.21, 0.29)*0.1;

    vec3 sunriseLightColor = vec3(1.5, 1.25, 0.75)*1.15;
    vec3 noonLightColor    = vec3(1.9, 1.88, 1.86)*1.25;
    vec3 sunsetLightColor  = vec3(1.5, 1.25, 0.75)*1.15;
    vec3 nightLightColor   = vec3(0.6, 0.6, 0.6);

    ambient = ((sunrise * sunriseAmbColor) + (noon * noonAmbColor) + (sunset * sunsetAmbColor))*clamp(1.0-rain, 0.35, 1.0) + (night * nightAmbColor);
    light = ((sunrise * sunriseLightColor) + (noon * noonLightColor) + (sunset * sunsetLightColor))*clamp(1.0-rain, 0.35, 1.0) + (night * nightLightColor);
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

float remap(float val, float min1, float max1, float min2, float max2) {
  return min2 + (val - min1) * (max2 - min2) / (max1 - min1);
}