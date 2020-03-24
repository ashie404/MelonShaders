#version 120

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;
varying mat3x3 tbn;

uniform mat4 gbufferModelViewInverse;

attribute vec4 at_tangent;

void main()
{
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    vec3 viewnormal = normalize(gl_NormalMatrix*gl_Normal);
    normal      = mat3(gbufferModelViewInverse)*viewnormal;

    #ifdef NORMAL
    vec3 viewtangent = normalize(gl_NormalMatrix*at_tangent.xyz);
    vec3 viewbinormal = normalize(gl_NormalMatrix*cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
    vec3 tangent = mat3(gbufferModelViewInverse) * viewtangent;
    vec3 binormal = mat3(gbufferModelViewInverse) * viewbinormal;
    tbn = mat3(tangent.x, binormal.x, normal.x,
                tangent.y, binormal.y, normal.y,
                tangent.z, binormal.z, normal.z);
    #endif
}