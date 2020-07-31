/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

#define MELONINFO 0 // Melon Shaders by June. V2.0. [0 1]

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 screenOut;

// Inputs from vertex shader
in vec2 texcoord;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex7;

uniform float sunAngle;

// Includes
#include "/lib/post/aces/ACES.glsl"

// other stuff
vec3 lookup(in vec3 textureColor) {
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

    vec2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

    float voffset = (LUTV*512.0)/3072.0;

    texPos1.y /= 6.0;
    texPos2.y /= 6.0;

    texPos1.y += voffset;
    texPos2.y += voffset;

    vec4 newColor1 = texture2D(colortex7, texPos1);
    vec4 newColor2 = texture2D(colortex7, texPos2);

    vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    return vec3(newColor.rgb);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    
    // ACES color grading (from Raspberry Shaders https://rutherin.netlify.app)
    ColorCorrection m;
	m.lum = vec3(0.2125, 0.7154, 0.0721);
    m.saturation = 0.95 + SAT_MOD;
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

    // convert back to srgb space
    color = linearToSrgb(color);

    #ifdef NIGHT_DESAT

    #if WORLD == 0
    float night = ((clamp(sunAngle, 0.50, 0.53)-0.50) / 0.03 - (clamp(sunAngle, 0.96, 1.00)-0.96) / 0.03);

    color = mix(color, vec3(luma(color)), mix(0.0, 0.5, clamp01(night-pow(luma(color), 3.0)*8.0)));
    #endif

    #endif

    #ifdef COLOR_AP1
    color = color * sRGB_2_AP1;
    #endif

    #ifdef LUT
    color = lookup(color);
    #endif

    screenOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;

void main() {
    gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif