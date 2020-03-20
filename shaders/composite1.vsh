#version 120

varying vec4 texcoord;
varying vec3 normal;

void main() {
    normal = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}