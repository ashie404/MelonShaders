#version 120

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex7;

varying vec3 normal;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

#include "lib/dither.glsl"
#include "lib/framebuffer.glsl"
#include "lib/raytrace.glsl"

void main() {
    vec4 color = texture2D(colortex0,texcoord);
    float z = texture2D(depthtex0, texcoord).r;

    float dither = bayer64(gl_FragCoord.xy);

    //NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;

    if (z < 1.0)
    {
        vec4 reflection = raytrace(fragpos.xyz,normal,dither);
		
		reflection.rgb *= color.rgb*2.0;
		vec3 spec = texture2D(colortex7,texcoord.xy).rgb;
		spec = 4.0*spec/(1.0-spec);
		
		color.rgb = reflection.rgb;
	}

    GCOLOR_OUT = color;
    GDEPTH_OUT = vec4(z, 0, 0, 0);
}