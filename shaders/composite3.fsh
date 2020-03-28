#version 450 compatibility

// composite pass 3: bloom pass 2

/* DRAWBUFFERS:012 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

in vec4 texcoord;

#include "/lib/settings.glsl"

const float weight[21] = float[] (0,	0,	0,0,0,0.000003,	0.000229,	0.005977,	0.060598,	0.24173,	0.382925,	0.24173,	0.060598,	0.005977,	0.000229,	0.000003,	0,	0,	0,	0,	0);

void main() {

    #ifdef BLOOM
    vec2 tex_offset = 1.0 / vec2(viewWidth, viewHeight); // gets size of single texel
    vec3 result = texture2D(colortex4, texcoord.st).rgb * weight[0]; // current fragment's contribution
    for(int i = 1; i < 21; ++i)
    {
        result += texture2D(colortex4, texcoord.st + vec2(0.0, tex_offset.y * i)).rgb * weight[i];
        result += texture2D(colortex4, texcoord.st - vec2(0.0, tex_offset.y * i)).rgb * weight[i];
    }
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    // output
    
    #ifdef BLOOM
    colortex0Out = color + vec4(result,1);
    #else
    colortex0Out = color;
    #endif
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
}