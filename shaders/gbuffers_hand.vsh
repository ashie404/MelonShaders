#version 450 compatibility

out vec3 tintColor;

out vec3 normal;

out vec4 texcoord;
out vec4 lmcoord;

void main() {
    gl_Position = ftransform();
    normal = normalize(gl_NormalMatrix * gl_Normal);
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
}