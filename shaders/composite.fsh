#version 450 compatibility

#extension GL_ARB_shader_texture_lod : enable

/* DRAWBUFFERS:0123 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex3Out;

// composite pass 0: sky and clouds

in vec4 texcoord;

in vec3 lightVector;
in vec3 lightColor;
in vec3 skyColor;
in float isNight;
uniform int worldTime;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D specular;
uniform sampler2D gdepthtex;
uniform sampler2D gaux2;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D normals;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform vec3 upPosition;

uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;

in float isTransparent;
in vec3 normal;

in vec4 position;
uniform int isEyeInWater;

#include "/lib/settings.glsl"
#include "/lib/util.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/shadow.glsl"
#include "/lib/sky.glsl"

void main() {

    vec3 finalColor = texture2D(colortex0, texcoord.st).rgb;
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);

    // if sky
    if (texture2D(depthtex0, texcoord.st).r == 1) {
        // render sky
        vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;

        finalColor = vec3(0);
        // get accurate atmospheric scattering
	    finalColor = GetSkyColor(worldPos, mat3(gbufferModelViewInverse) * sunPosition, isNight);
        // draw stars based on night transition value
        finalColor += mix(vec3(0), DrawStars(normalize(worldPos)), isNight);
    }
    
    // output
    
    colortex0Out = vec4(finalColor, 1);
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
    colortex3Out = texture2D(colortex3, texcoord.st);
}