#version 120

const bool lut = true;
const float shadowMapBias = 0.85;
const int noiseTextureResolution = 256;

varying vec4 texcoord;

#include "lib/settings.glsl"
#include "lib/generic.glsl"
#include "lib/shadows.glsl"

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

void main() {
    depth = texture2D(depthtex1, texcoord.st).r;
    vec3 color = texture2D(colortex0, texcoord.st).rgb;
    color = calculateLighting(color);

    color = lookup(color, colortex7);

    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(depth);
}