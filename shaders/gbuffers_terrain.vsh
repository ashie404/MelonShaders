#version 450 compatibility

out vec3 tintColor;
out vec3 normal;

attribute vec4 at_tangent;

out vec4 texcoord;
out vec4 lmcoord;

out mat3 viewTBN;
out mat3 worldTBN;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float viewHeight;
uniform float viewWidth;
uniform float frameTimeCounter;

attribute vec4 mc_Entity;
out float id;

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

void main()
{
    #ifndef ISOMETRIC
    gl_Position = ftransform();
    #else
    gl_Position = gl_ModelViewMatrix * gl_Vertex * vec4(1 * (viewHeight / viewWidth), 1, -0.01, 8);
    #endif

    // waving
    #ifdef WAVING_TERRAIN
    if (mc_Entity.x == 31) {
        gl_Position.x += sin(frameTimeCounter*cellular(gl_Vertex.xyz)*4)/16;
    }
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
    
    id = mc_Entity.x;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}