#version 120

// composite pass 1: reflections

varying vec4 texcoord;
varying vec3 normal;

uniform int worldTime;

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

uniform vec3 upPosition;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;


#include "lib/settings.glsl"
#include "lib/framebuffer.glsl"
#include "lib/common.glsl"
#include "lib/dither.glsl"
#include "lib/raytrace.glsl"

void main() {
    
    vec4 finalColor = texture2D(colortex0, texcoord.st);

    Fragment frag = getFragment(texcoord.st);
    // calculate screen space reflections
    #ifdef SCREENSPACE_REFLECTIONS
    float z = texture2D(depthtex0, texcoord.st).r;
    float dither = bayer64(gl_FragCoord.xy);
    //NDC Coordinate
	vec4 fragpos = normalize(gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0));
	fragpos /= fragpos.w;

    // water reflections
    if (frag.emission == 0.5) {
        vec4 reflection = raytrace(fragpos.xyz,normal,dither);
        
        // set alpha
        if (reflection.a > 0)
        {
            reflection.a = 0.85;
        }
		reflection.rgb *= finalColor.rgb / 1.5;

		finalColor.rgb = mix(finalColor.rgb, reflection.rgb, reflection.a);
    }
    // ice reflections
    #ifdef ICE_REFLECTIONS
    if (frag.emission == 0.4) {
        vec4 reflection = raytrace(fragpos.xyz,normal,dither);

        // set alpha
        if (reflection.a > 0)
        {
            reflection.a = 0.65;
        }
		
		reflection.rgb *= finalColor.rgb / 1.5;
		
		finalColor.rgb = mix(finalColor.rgb, reflection.rgb, reflection.a);
    }
    #endif
    #endif
    finalColor.a = 1;
    GCOLOR_OUT = finalColor;
}