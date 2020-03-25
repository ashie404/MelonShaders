#version 120

#extension GL_ARB_shader_texture_lod : enable

#include "/lib/settings.glsl"
#include "/lib/aces/ACES.glsl"

#define DEBUG finalColor // Debug output. If not debugging, finalColor should be used. [finalColor compColor shadow0 shadow1 shadowColor specDebug]

#define INFO 0 //[0 1]
#define INFO2 0 //[0 1]

const bool gcolorMipmapEnabled = true;

varying vec4 texcoord;

uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D gcolor;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform float viewHeight;
uniform float viewWidth;

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

    // tonemapping
    #ifdef TONEMAP_ACES
    // ACES Tonemap (the real one)
    // Tonemap code from Raspberry Shaders https://rutherin.netlify.com
    color = FilmToneMap(color);
    #endif
    
    // convert linear back to gamma
    color = pow(color, vec3(1 / 2.2));

    // auto exposure
    //autoExposure(color);

    // apply lut
    color = lookup(color, colortex6);

    #ifdef VIGNETTE
    vignette(color);
    #endif

    vec4 finalColor = vec4(color, 1);

    vec4 shadow0 = texture2D(shadowtex0, texcoord.st);
    vec4 shadow1 = texture2D(shadowtex1, texcoord.st);
    vec4 shadowColor = texture2D(shadowcolor0, texcoord.st);
    vec4 compColor = texture2D(gcolor, texcoord.st);
    vec4 specDebug = texture2D(colortex3, texcoord.st);

    gl_FragColor = DEBUG;
}