#version 120

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;
varying float isWater;

uniform sampler2D noisetex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;

uniform sampler2D gdepthtex;
uniform sampler2D shadow;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

uniform vec3 cameraPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;

varying vec3 normal;

#include "lib/settings.glsl"
#include "lib/framebuffer.glsl"
#include "lib/common.glsl"
#include "lib/shadow.glsl"
#include "lib/dither.glsl"
#include "lib/raytrace.glsl"

/* DRAWBUFFERS:012 */

void main() {
    // get current fragment and calculate lighting
    Fragment frag = getFragment(texcoord.st);
    Lightmap lightmap = getLightmapSample(texcoord.st);
    vec3 finalColor = calculateLighting(frag, lightmap);

    // calculate screen space reflections
    #ifdef SCREENSPACE_REFLECTIONS
    float z = texture2D(depthtex0, texcoord.st).r;
    float dither = bayer64(gl_FragCoord.xy);
    //NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;

    if (frag.emission == 0.5) {
        vec4 reflection = raytrace(fragpos.xyz,normal,dither);
		
		reflection.rgb *= finalColor.rgb / 1.5;
		
		finalColor.rgb = mix(finalColor.rgb, reflection.rgb, reflection.a);
    }
    #endif
    // output
    GCOLOR_OUT = vec4(finalColor, 1.0);
}