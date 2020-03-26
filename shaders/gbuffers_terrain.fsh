#version 120

#include "/lib/framebuffer.glsl"

uniform sampler2D texture;

uniform sampler2D specular;
uniform sampler2D normals;

uniform int worldTime;

varying vec3 tintColor;
varying vec3 normal;
varying mat3 viewTBN;
varying mat3 worldTBN;


varying vec4 texcoord;
varying vec4 lmcoord;

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

    /* DRAWBUFFERS:0123 */
    gl_FragData[0] = blockColor;
    gl_FragData[1] = vec4(lmcoord.st / 16,0,0);
    gl_FragData[2] = vec4(normalData * 0.5 + 0.5, 1.0);
    gl_FragData[3] = texture2D(specular, texcoord.st);
}