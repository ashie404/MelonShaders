#version 120

varying vec3 tintColor;
varying vec3 normal;

attribute vec4 at_tangent;

varying vec4 texcoord;
varying vec4 lmcoord;

varying mat3 viewTBN;
varying mat3 worldTBN;

uniform mat4 gbufferModelViewInverse;

attribute vec4 mc_Entity;
varying float id;

#include "/lib/settings.glsl"

void main()
{
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    #ifdef NORMAL_MAP

    vec3 normal   = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent  = normalize(gl_NormalMatrix * (at_tangent.xyz));

         viewTBN  = transpose(mat3(tangent, normalize(cross(tangent, normal)), normal));

         normal   = mat3(gbufferModelViewInverse) * normal;
         tangent  = mat3(gbufferModelViewInverse) * tangent;

    vec3 binormal = normalize(cross(tangent, normal));

         worldTBN = transpose(mat3(tangent, binormal, normal));
								  
	//viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
    #endif
    
    id = mc_Entity.x;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}