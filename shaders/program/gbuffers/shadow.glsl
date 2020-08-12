/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 shadowcolorOut;

// Inputs from vertex shader

in vec2 texcoord;
in vec4 glcolor;
in float water;

// Uniforms

uniform int entityId;

uniform sampler2D texture;

void main() {
	if (water > 0.5 || entityId == 7) {
		discard;
	} else {
		vec4 color = texture2D(texture, texcoord) * glcolor;
		shadowcolorOut = color;
	}
}


#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec4 glcolor;
out float water;

// Uniforms
attribute vec3 mc_Entity;
attribute vec3 mc_midTexCoord;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

// Includes
#include "/lib/vertex/distortion.glsl"
#include "/lib/util/noise.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

	gl_Position = ftransform();

	#ifdef WIND
    if ((mc_Entity.x == 20.0 && gl_MultiTexCoord0.t < mc_midTexCoord.t) || mc_Entity.x == 21) {
		vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
        position.x += (sin((frameTimeCounter*2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
        position.z += (sin((frameTimeCounter/2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
		gl_Position = shadowProjection * shadowModelView * position;
    }
    #endif

    if (mc_Entity.x == 8.0) {
		water = 1.0;
	} else {
		water = 0.0;
	}

    gl_Position.xyz = distortShadow(gl_Position.xyz);
}

#endif