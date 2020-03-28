#version 450 compatibility

/* DRAWBUFFERS:012 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D texture;
uniform sampler2D depthtex1;

in vec3 tintColor;
in vec3 normal;

in vec4 texcoord;
in vec4 lmcoord;

in vec4 position;
in float isWater;
in float isIce;
in float isTransparent;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    
    if (isWater == 1) {
        colortex0Out = vec4(0, 0, 0, 0.22);
        colortex1Out = vec4(lmcoord.st / 16,0,0.5);
    } else {
        colortex0Out = blockColor;
        colortex1Out = vec4(lmcoord.st / 16,0,0.1);
    }
    colortex2Out = vec4(normal * 0.5 + 0.5, 1.0);
}