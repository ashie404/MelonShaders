#version 120

// composite pass 3: bloom pass 2

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

varying vec4 texcoord;

#include "/lib/settings.glsl"
#include "/lib/blur.glsl"

void main() {

    #ifdef BLOOM
    vec4 bloom = texture2D(colortex4, texcoord.st);
    for (int i = 0; i < 5; ++i) {
        bloom += blur13(colortex4, texcoord.st, vec2(viewWidth, viewHeight), vec2(0, i));
    }
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    /* DRAWBUFFERS:012 */
    #ifdef BLOOM
    gl_FragData[0] = color + bloom;
    #else
    gl_FragData[0] = color;
    #endif
    gl_FragData[1] = texture2D(gdepth, texcoord.st);
    gl_FragData[2] = texture2D(gnormal, texcoord.st);
}