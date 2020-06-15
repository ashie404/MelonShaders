/* 
    Melon Shaders by June
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 shadowcolor0Out;

// inputs from vertex shader

in vec2 texcoord;
in vec4 color;
in float isWater;

// uniforms

uniform sampler2D texture;

void main() {
	if (isWater > 0.5) {
		discard;
	} else {
		vec4 color = texture2D(texture, texcoord) * color;
		shadowcolor0Out = color;
	}
}

#endif

// VERTEX SHADER //

#ifdef VERT

// outputs to fragment shader

out vec2 texcoord;
out vec4 color;
out float isWater;

// uniforms
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

attribute vec3 mc_Entity;
attribute vec3 mc_midTexCoord;

// includes

#include "/lib/noise.glsl"
#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;

	vec4 position = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	#ifdef WIND
    if ((mc_Entity.x == 20.0 && gl_MultiTexCoord0.t < mc_midTexCoord.t) || mc_Entity.x == 23) {
        position.xz += (sin(frameTimeCounter*cellular(position.xyz + cameraPosition)*4)/16)*WIND_STRENGTH;
    }
    #endif

	gl_Position = gl_ProjectionMatrix * shadowModelView * position;
	gl_Position.xyz = distort(gl_Position.xyz);
	if (mc_Entity.x == 8.0) {
		isWater = 1.0;
	} else {
		isWater = 0.0;
	}
}

#endif