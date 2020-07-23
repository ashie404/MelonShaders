/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 screenOut;

// Inputs from vertex shader
in vec2 texcoord;


// Uniforms
uniform sampler2D colortex0;


// Includes
#include "/lib/post/aces/ACES.glsl"


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

    #ifdef COLOR_AP1
    color = color * sRGB_2_AP1;
    #endif

    screenOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;


// Uniforms



// Includes



void main() {
    gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif