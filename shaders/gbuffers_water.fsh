#version 120

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D texture;
uniform sampler2D depthtex1;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

varying vec4 position;
varying float isWater;
varying float isIce;
varying float isTransparent;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    gl_FragData[0] = blockColor;
    if (isWater == 1) {
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.5);
    } else {
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.1);
    }
    gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
}