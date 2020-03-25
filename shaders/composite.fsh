#version 120

// composite pass 0: sky and clouds

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;
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

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;

varying float isTransparent;
varying vec3 normal;

varying vec4 position;
uniform int isEyeInWater;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/util.glsl"
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
        finalColor = vec3(0);

        // get accurate atmospheric scattering
	    finalColor = GetSkyColor(mat3(gbufferModelViewInverse) * viewPos.xyz, mat3(gbufferModelViewInverse) * sunPosition, isNight);
        // if night time, draw stars
        if (isNight == 1) {
            vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
            finalColor += DrawStars(normalize(worldPos));
        }
    }
    
    // output
    /* DRAWBUFFERS:0123 */
    gl_FragData[0] = vec4(finalColor, 1);
    gl_FragData[1] = texture2D(gdepth, texcoord.st);
    gl_FragData[2] = texture2D(gnormal, texcoord.st);
    gl_FragData[3] = texture2D(colortex3, texcoord.st);
}