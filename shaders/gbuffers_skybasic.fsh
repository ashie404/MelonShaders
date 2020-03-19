#version 120

#include "lib/settings.glsl"

varying vec3 upVec;

uniform vec3 sunPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;

#include "lib/sky.glsl"

void main() {

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    
	vec3 color = GetSkyColor(vec3(viewPos.x, dot(viewPos.xyz, upVec), viewPos.z), sunPosition);
    
    gl_FragData[0] = vec4(color, 1.0);
}