#version 450 compatibility

/* DRAWBUFFERS:0123 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex3Out;

// inputs from vertex shader

in vec3 tintColor;
in vec3 normal;
in mat3 viewTBN;
in mat3 worldTBN;
in vec4 texcoord;
in vec4 lmcoord;
in float id;
in vec4 position;

// uniforms

uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

// constants

const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

// includes

#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/framebuffer.glsl"

vec4 getTangentNormals(vec2 coord) {
    vec4 normal = texture2D(normals,  coord) * 2.0 - 1.0;
    return normal;
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);

    vec3 normalData = normal;

    #ifdef NORMAL_MAP
    vec4 normalTex = getTangentNormals(texcoord.st);
    normalData = normalize((normalTex.xyz) * viewTBN);
    #endif

    // floating point precision correction
    int idCorrected = int(id + 0.5);
    
    if (idCorrected == 31 || idCorrected == 32) {
        // subsurf scattering
        blockColor.rgb *= tintColor;
        colortex1Out = vec4(lmcoord.st / 16,0,0.3);
    } else if (idCorrected == 21) {
        // emissives
        if (luma(blockColor.rgb) > 0.525) {
            blockColor.rgb *= 5*(luma(blockColor.rgb)+0.525);
        }
        colortex1Out = vec4(lmcoord.st / 16,0,1);
    } else {
        blockColor.rgb *= tintColor;
        // everything else
        colortex0Out = blockColor;
        colortex1Out = vec4(lmcoord.st / 16,0,0);
    }
    colortex0Out = blockColor;
    colortex2Out = vec4(normalData * 0.5 + 0.5, 1.0);
    colortex3Out = texture2D(specular, texcoord.st);
}