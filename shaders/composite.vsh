#version 120

varying vec4 texcoord;

void main() {
    gl_Position = gl_MultiTexCoord0 * 2.0 - 1.0;
    texcoord = gl_MultiTexCoord0;
}