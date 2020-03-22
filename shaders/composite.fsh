#version 120

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
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D gdepthtex;
uniform sampler2D gaux2;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

uniform vec3 cameraPosition;

uniform vec3 upPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;

varying float isTransparent;
varying vec3 normal;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/common.glsl"
#include "/lib/shadow.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/noise.glsl"

/* DRAWBUFFERS:012 */

void main() {

    vec3 finalColor = texture2D(colortex0, texcoord.st).rgb;
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);


    // calculate shadowmapped lighting for translucents (except for water)
    // 0.1 emission marks translucent
    if (frag.emission == 0.1) {
        finalColor = calculateBasicLighting(frag, lightmap);
    }
    // 0.5 emission marks water, calculate basic lighting so shadows aren't cast on water
    else if (frag.emission == 0.5) {
        finalColor = calculateBasicLighting(frag, lightmap);
    }

    // calculate screen space reflections
    /*
    #ifdef SCREENSPACE_REFLECTIONS
    float z = texture2D(depthtex0, texcoord.st).r;
    float dither = bayer64(gl_FragCoord.xy);
    //NDC Coordinate
	//vec4 fragpos = normalize(gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0));
    vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
    vec3 viewPos = toNDC(screenPos);

    //vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));
	//fragpos /= fragpos.w;
    // water reflections
    if (frag.emission == 0.5) {
        vec4 reflection = reflection(normalize(viewPos),toNDC(normal),dither);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));

        // set alpha
        if (reflection.a > 0)
        {
            reflection.a = 0.85;
        }
        if (isNight == 1) {
            reflection.rgb += finalColor.rgb;
        }
        else {
		    reflection.rgb *= finalColor.rgb;
        }

		finalColor.rgb = mix(finalColor.rgb, reflection.rgb, reflection.a);
    }
    // ice reflections
    #ifdef ICE_REFLECTIONS
    if (frag.emission == 0.4) {
        vec4 reflection = reflection(normalize(viewPos),normal,dither);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));

        // set alpha
        if (reflection.a > 0)
        {
            reflection.a = 0.65;
        }
        if (isNight == 1) {
            reflection.rgb += finalColor.rgb;
        }
        else {
		    reflection.rgb *= finalColor.rgb;
        }
		
		reflection.rgb *= finalColor.rgb;
		
		finalColor.rgb = mix(finalColor.rgb, reflection.rgb, reflection.a);
    }
    #endif
    #endif*/

    // output
    gl_FragData[0] = vec4(finalColor, 1);
}