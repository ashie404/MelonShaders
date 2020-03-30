#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 colortex0Out;

#include "/lib/settings.glsl"
#include "/lib/aces/ACES.glsl"

#define DEBUG finalColor // Debug output. If not debugging, finalColor should be used. [finalColor compColor shadow0 shadow1 shadowColor specDebug normal]

#define INFO 0 //[0 1]

const bool gcolorMipmapEnabled = true;

in vec4 texcoord;

uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform float viewHeight;
uniform float viewWidth;
in float nightDesaturation;

void vignette(inout vec3 color) {
    float dist = distance(texcoord.st, vec2(0.5));
    dist /= 1.5142;
    dist = pow(dist, 1.1);

    color.rgb *= 1.0 - dist;
}

vec3 lookup(in vec3 textureColor, in sampler2D lookupTable) {
    #ifndef LUT
    return textureColor;
    #endif
    
    textureColor = clamp(textureColor, 0.0, 1.0);
    float blueColor = textureColor.b * 63.0;

    vec2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);

    vec2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);

    vec2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
    
    #ifdef INVERT_Y_LUT
    texPos1.y = -texPos1.y;
    #endif

    vec2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
    
    #ifdef INVERT_Y_LUT
    texPos2.y = -texPos2.y;
    #endif

    vec4 newColor1 = texture2D(lookupTable, texPos1);
    vec4 newColor2 = texture2D(lookupTable, texPos2);

    vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return vec3(newColor.rgb);
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

void autoExposure(inout vec3 color){
	float exposureLod = log2(max(viewWidth, viewHeight));

	float exposure = luma(texture2DLod(gcolor, vec2(0.5), exposureLod).rgb);
	exposure = clamp(exposure, 0.001, 0.15);
	
	color /= 2.5 * exposure;
}

void main() {
    vec3 color = texture2D(gcolor, texcoord.st).rgb;

    // create new night desaturation value based on how lit an area is
    float nightDesat = mix(nightDesaturation, 0.0, texture2D(gdepth, texcoord.st).r/16);

    // tonemapping
    #ifdef TONEMAP_ACES
    // ACES Tonemap (the real one)
    // Tonemap code from Raspberry Shaders https://rutherin.netlify.com

    ColorCorrection m;
	m.lum = vec3(0.2125, 0.7154, 0.0721);
	m.saturation = 0.95 + SAT_MOD - nightDesat;
	m.vibrance = VIB_MOD;
	m.contrast = 1.0 - CONT_MOD;
	m.contrastMidpoint = CONT_MIDPOINT;

	m.gain = vec3(1.0, 1.0, 1.0) + GAIN_MOD; //Tint Adjustment
	m.lift = vec3(0.0, 0.0, 0.0) + LIFT_MOD * 0.01; //Tint Adjustment
	m.InvGamma = vec3(1.0, 1.0, 1.0);

    color = FilmToneMap(color);
    color = WhiteBalance(color);
	color = Vibrance(color, m);
	color = Saturation(color, m);
    color = Contrast(color, m);
    color = LiftGammaGain(color, m);
    #else

    // just do night time desaturation if aces is disabled
    ColorCorrection m;
    m.lum = vec3(0.2125, 0.7154, 0.0721);
    m.saturation = 0.95 - nightDesat;

    color = Saturation(color, m);
    #endif
    
    color = linearToSrgb(color);

    // apply lut
    color = lookup(color, colortex6);

    #ifdef VIGNETTE
    vignette(color);
    #endif

    color = clamp01(color);

    vec4 finalColor = vec4(color, 1);

    vec4 shadow0 = texture2D(shadowtex0, texcoord.st);
    vec4 shadow1 = texture2D(shadowtex1, texcoord.st);
    vec4 shadowColor = texture2D(shadowcolor0, texcoord.st);
    vec4 compColor = texture2D(gcolor, texcoord.st);
    vec4 specDebug = texture2D(colortex3, texcoord.st);
    vec4 normal = texture2D(gnormal, texcoord.st);

    colortex0Out = DEBUG;
}