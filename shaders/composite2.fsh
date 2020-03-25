#version 120

// composite pass 2: bloom pass 1

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
    vec4 bloomHoriz = vec4(0,0,0,1); 
    for (int i = 0; i < 5; ++i) {
        bloomHoriz += blur13(colortex4, texcoord.st, vec2(viewWidth, viewHeight), vec2(i,0));
    }
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    /* DRAWBUFFERS:0124 */
    gl_FragData[0] = color;
    gl_FragData[1] = texture2D(gdepth, texcoord.st);
    gl_FragData[2] = texture2D(gnormal, texcoord.st);
    #ifdef BLOOM
    gl_FragData[3] = bloomHoriz;
    #endif
}