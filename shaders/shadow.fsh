#version 120

uniform sampler2D tex;
uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 color;
varying float isTransparent;

void main() {
    if (texture2D(texture, texcoord).a < 0.35) {
        discard;
    }

    vec3 fragColor = color.rgb * texture2D(tex, texcoord).rgb;
    fragColor = mix(vec3(0), fragColor, isTransparent);

    gl_FragData[0] = vec4(fragColor, 1.0);
}