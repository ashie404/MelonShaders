#version 450 compatibility

// composite pass 2: bloom pass 1

/* DRAWBUFFERS:0124 */
layout (location = 0) out vec4 colortex0Out;
layout (location = 1) out vec4 colortex1Out;
layout (location = 2) out vec4 colortex2Out;
layout (location = 3) out vec4 colortex4Out;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D colortex3;

uniform float viewWidth;
uniform float viewHeight;

in vec4 texcoord;

#include "/lib/settings.glsl"

void main() {

    #ifdef BLOOM
    vec2 tex_offset = 1.0 / vec2(viewWidth, viewHeight); // gets size of single texel
    vec3 result = texture2D(colortex4, texcoord.st).rgb; // current fragment's contribution
    for(int i = 1; i <= 64; ++i)
    {
        float weight = 0.25 / (i * i + 1.0);
        result += texture2D(colortex4, texcoord.st + vec2(tex_offset.x * i, 0.0)).rgb * weight;
        result += texture2D(colortex4, texcoord.st - vec2(tex_offset.x * i, 0.0)).rgb * weight;
    }
    #endif
    vec4 color = texture2D(colortex0, texcoord.st);

    // output

    colortex0Out = color;
    colortex1Out = texture2D(gdepth, texcoord.st);
    colortex2Out = texture2D(gnormal, texcoord.st);
    #ifdef BLOOM
    colortex4Out = vec4(result,1);
    #endif
}