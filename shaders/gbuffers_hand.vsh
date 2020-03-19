#version 120

varying vec3 tintColor;

varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

void main() {
    gl_Position = ftransform();
    normal = normalize(gl_NormalMatrix * gl_Normal);
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
}