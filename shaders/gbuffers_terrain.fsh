#version 450 compatibility

/* DRAWBUFFERS:0123 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex3Out;

#include "/lib/framebuffer.glsl"

uniform sampler2D texture;

uniform sampler2D specular;
uniform sampler2D normals;

uniform int worldTime;

in vec3 tintColor;
in vec3 normal;
in mat3 viewTBN;
in mat3 worldTBN;


in vec4 texcoord;
in vec4 lmcoord;

in float id;

#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"

vec4 getTangentNormals(vec2 coord) {
    vec4 normal = texture2D(normals,  coord) * 2.0 - 1.0;
    return normal;
}

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    vec3 normalData = normal;

    #ifdef NORMAL_MAP
    vec4 normalTex = getTangentNormals(texcoord.st);
    normalData = normalize((normalTex.xyz) * viewTBN);
    #endif


    colortex0Out = blockColor;

    // floating point precision correction
    int idCorrected = int(id + 0.5);
    
    if (idCorrected == 31 || idCorrected == 32) {
        // subsurf scattering
        colortex1Out = vec4(lmcoord.st / 16,0,0.3);
    } else if (idCorrected == 21) {
        // emissives
        colortex1Out = vec4(lmcoord.st / 16,0,1);
    } else {
        // everything else
        colortex1Out = vec4(lmcoord.st / 16,0,0);
    }
    colortex2Out = vec4(normalData * 0.5 + 0.5, 1.0);
    colortex3Out = texture2D(specular, texcoord.st);
}