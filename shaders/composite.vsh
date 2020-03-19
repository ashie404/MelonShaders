#version 120

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 lightColor;
varying vec3 skyColor;

void main() {
    if (worldTime < 12700 || worldTime > 23250) {
        lightVector = normalize(sunPosition);
        lightColor = vec3(1.0);
        skyColor = vec3(0.003);
    } 
    else {
        lightVector = normalize(moonPosition);
        lightColor = vec3(0.1);
        skyColor = vec3(0.0003);
    }
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}