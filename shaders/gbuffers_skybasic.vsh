#version 120

varying float isNight;

uniform int worldTime;
varying vec4 texcoord;

void main(){
	if (worldTime < 12700 || worldTime > 23250) {
        isNight = 0;
    } 
    else {
        isNight = 1;
    }
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
}