#version 120

uniform sampler2D texture;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    gl_FragData[0] = blockColor;
}