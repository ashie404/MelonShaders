#version 450 compatibility

// outputs to fragment shader

out vec3 tintColor;
out vec3 normal;
out vec4 texcoord;
out vec4 lmcoord;
out mat3 viewTBN;
out mat3 worldTBN;

// uniforms

uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferModelViewInverse;
attribute vec4 at_tangent;

// includes

#include "/lib/settings.glsl"

void main()
{
    #ifndef ORTHOGRAPHIC
    gl_Position = ftransform();
    #else
    gl_Position = gl_ModelViewMatrix * gl_Vertex * vec4(1 * (viewHeight / viewWidth), 1, -0.01, 8);
    #endif
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
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
}