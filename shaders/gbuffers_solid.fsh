#version 120

#include "/lib/framebuffer.glsl"

uniform sampler2D texture;

uniform sampler2D specular;

uniform sampler2D normals;

uniform int worldTime;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

varying mat3x3 tbn;

#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;
    vec3 finalNormal = normal;

    #ifdef NORMAL
    // calculate normal map stuff
    finalNormal = decodeLabNormal(texture2D(normals, texcoord.st), tbn);
    #endif

    /* DRAWBUFFERS:0123 */
    gl_FragData[0] = blockColor;
    gl_FragData[1] = vec4(lmcoord.st / 16,0,0);
    gl_FragData[2] = vec4(toWorld(finalNormal), 1.0);
    gl_FragData[3] = texture2D(specular, texcoord.st);
}