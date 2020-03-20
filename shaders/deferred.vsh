#version 120

varying vec2 texcoord;

varying vec3 normal;

void main(){
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
}
