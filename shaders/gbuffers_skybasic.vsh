#version 120

varying float isNight;

uniform float worldTime;
varying vec4 texcoord;

void main(){
	if (worldTime < 12700 || worldTime > 23250) {
        isNight = 1;
    } 
    else {
        isNight = 0;
    }
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
}