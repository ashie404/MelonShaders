/*
    Melon Shaders by June
    https://j0sh.cf
*/

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const bool colortex6Clear = false;
*/

#define clamp01(p) (clamp(p, 0.0, 1.0))
#define log10(x) log(x) / log(10.0)

uniform float screenBrightness;
const float PI = 3.1415926535897;

void calcLightingColor(in float angle, in float rain, in vec3 spos, in vec3 slpos, out vec3 ambient, out vec3 light) {

    float sunrise  = ((clamp(angle, 0.96, 1.00)-0.96) / 0.04 + 1-(clamp(angle, 0.02, 0.15)-0.02) / 0.13);
    float noon     = ((clamp(angle, 0.02, 0.15)-0.02) / 0.13   - (clamp(angle, 0.35, 0.48)-0.35) / 0.13);
    float sunset   = ((clamp(angle, 0.35, 0.48)-0.35) / 0.13   - (clamp(angle, 0.50, 0.53)-0.50) / 0.03);
    float night    = ((clamp(angle, 0.50, 0.53)-0.50) / 0.03   - (clamp(angle, 0.96, 1.00)-0.96) / 0.03);

    vec3 sunriseAmbColor = vec3(0.33, 0.28, 0.23)*0.5;
    vec3 noonAmbColor    = vec3(0.37, 0.39, 0.58)*0.75;
    vec3 sunsetAmbColor  = vec3(0.33, 0.28, 0.23)*0.5;
    vec3 nightAmbColor   = vec3(0.19, 0.21, 0.29)*0.075;

    vec3 sunriseLightColor = vec3(1.5, 0.6, 0.15)*2.5;
    vec3 noonLightColor    = vec3(1.0, 0.99, 0.96)*5.0;
    vec3 sunsetLightColor  = vec3(1.5, 0.6, 0.15)*2.5;
    vec3 nightLightColor   = vec3(0.6, 0.6, 0.6)*0.15;

    ambient = ((sunrise * sunriseAmbColor) + (noon * noonAmbColor) + (sunset * sunsetAmbColor)) + (night * nightAmbColor);

    if (all(equal(slpos, spos))) {
      light = ((sunrise * sunriseLightColor) + (noon * noonLightColor) + (sunset * sunsetLightColor) + (night * nightLightColor)) * clamp(1.0-rain, 0.1, 1.0);
    } else {
      light = nightLightColor*clamp(1.0-rain, 0.1, 1.0);
    }
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

float fresnel(float bias, float scale, float power, vec3 I, vec3 N)
{
    return bias + scale * pow(1.0 + dot(I, N), power);
}