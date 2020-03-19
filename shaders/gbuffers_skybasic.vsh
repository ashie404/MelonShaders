#version 120

varying vec4 texcoord;

varying vec3 upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

#include "lib/settings.glsl"

void main(){
	upVec = normalize(gbufferModelView[1].xyz);
	gl_Position = ftransform();
}