#version 120

#extension GL_ARB_shader_texture_lod : enable

// deferred pass 1: reflections on solid terrain

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
uniform sampler2D colortex5;
uniform sampler2D depthtex0;

uniform sampler2D gdepthtex;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

uniform vec3 cameraPosition;

uniform vec3 upPosition;

uniform vec3 shadowLightPosition;

uniform float viewWidth;
uniform float viewHeight;

varying vec3 normal;

uniform sampler2D specular;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/util.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/shadow.glsl"
#include "/lib/distort.glsl"

void main() {
    float z = texture2D(depthtex0, texcoord.st).r;
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    
    vec3 finalColor = texture2D(colortex0, texcoord.st).rgb;

    /*vec4 screenPos = vec4(texcoord.st, z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;*/

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;

    vec3 worldPos = toWorld(viewPos.xyz);

    #ifdef SPECULAR
    #ifdef SCREENSPACE_REFLECTIONS
    #ifdef SPECULAR_REFLECTIONS
    PBRData pbrData = getPBRData(texture2D(colortex3, texcoord.st));
    float roughness = pow(1 - pbrData.smoothness, 2);
    // get pbr data and calculate SSR if enabled
    if (roughness < 0.25) {
        if (z != 1) {
            // bayer64 dither
            float dither = bayer64(gl_FragCoord.xy);
            // calculate ssr color
            vec4 reflection = Reflection(viewPos.xyz, frag.normal, dither, colortex0, roughness);
            //reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
            //reflection.rgb /= 16;
            finalColor *= mix(vec3(1), reflection.rgb, reflection.a-roughness);
        } else {

        }
    }
    #endif
    #endif
    #endif

    /* DRAWBUFFERS:0352 */
    gl_FragData[0] = vec4(finalColor, 1);
    gl_FragData[1] = texture2D(colortex3, texcoord.st);
    gl_FragData[3] = texture2D(gnormal, texcoord.st);
    
    #ifdef SCREENSPACE_REFLECTIONS
	gl_FragData[2] = vec4(pow(finalColor, vec3(0.125)) * 0.5, float(z < 1.0)); //gaux2
    #endif
}