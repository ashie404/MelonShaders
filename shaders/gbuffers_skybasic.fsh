#version 120

uniform vec3 sunPosition;

varying float isNight;

varying vec4 texcoord;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/sky.glsl"

void main() {

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    
	vec3 color = GetSkyColor(mat3(gbufferModelViewInverse) * viewPos.xyz, mat3(gbufferModelViewInverse) * sunPosition, isNight);
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}