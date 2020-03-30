#version 450 compatibility

/* DRAWBUFFERS:012 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;

// inputs from vertex shader

in vec3 tintColor;
in vec3 normal;

in vec4 texcoord;
in vec4 lmcoord;

// uniforms

uniform sampler2D texture;

// includes

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"

void main() {
    vec4 handColor = texture2D(texture, texcoord.st);
    handColor.rgb *= tintColor;

    colortex0Out = handColor;
    colortex1Out = vec4(lmcoord.st / 16, 0, 0);
    colortex2Out = vec4(normal * 0.5 + 0.5, 1.0);
}