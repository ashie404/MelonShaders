#version 120

attribute vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec4 shadowPos;

varying vec3 lightColor;
varying vec3 skyColor;
varying float isNight;

uniform float worldTime;

#include "/lib/distort.glsl"
#include "/lib/settings.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix * gl_Normal));
	#ifdef EXCLUDE_FOLIAGE
		//when EXCLUDE_FOLIAGE is enabled, act as if foliage is always facing towards the sun.
		//in other words, don't darken the back side of it unless something else is casting a shadow on it.
		if (lightDot > 0.0 || mc_Entity.x == 10000.0) {
	#else
		if (lightDot > 0.0) { //vertex is facing towards the sun
	#endif
		vec4 pos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
		shadowPos = shadowProjection * (shadowModelView * pos); //apply shadow projection
		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor); //apply shadow distortion
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5; //convert from -1 ~ +1 to 0 ~ 1
		shadowPos.z -= SHADOW_BIAS * (distortFactor * distortFactor) / abs(lightDot); //apply shadow bias
		shadowPos.w = 1.0; //mark that this vertex should check the shadow map
		gl_Position = gl_ProjectionMatrix * (gbufferModelView * pos);
	}
	else { //vertex is facing away from the sun
		gl_Position = ftransform();
		lmcoord.y *= SHADOW_BRIGHTNESS; //guaranteed to be in shadows. reduce light level immediately.
		shadowPos = vec4(0.0); //mark that this vertex does not need to check the shadow map.
	}

	if (worldTime < 12700 || worldTime > 23250) {
        lightColor = vec3(1.0);
        skyColor = vec3(0.012, 0.015, 0.03);
        isNight = 0;
    } 
    else {
        lightColor = vec3(0.1);
        skyColor = vec3(0.0012, 0.0015, 0.003);
        isNight = 1;
    }
}