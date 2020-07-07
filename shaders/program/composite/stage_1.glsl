/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:045 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 bloomOut;

/*
const float centerDepthSmoothHalflife = 4.0;
*/

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;

#include "/lib/poisson.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    #ifdef DOF
    float currentDepth = texture2D(depthtex0, texcoord).r;
    vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

    int dofSteps = 8*DOF_QUALITY;

    // distance blur
    if (currentDepth >= centerDepthSmooth) {
        vec3 blurred = vec3(0.0);
        float blurSize = clamp((currentDepth-centerDepthSmooth)*(256.0*APERTURE), 0.0, (12.0*APERTURE));
        for (int i = 0; i <= dofSteps; i++) {
                vec2 offset = poissonDisk[i] * oneTexel * blurSize;
                #ifdef CHROM_ABB
                float g = texture2D(colortex0, texcoord + offset + vec2(blurSize * oneTexel.x, 0.0)).g;
                vec2 rb = texture2D(colortex0, texcoord + offset).rb;
                blurred += vec3(rb.x, g, rb.y);
                #else
                blurred += texture2D(colortex0, texcoord + offset).rgb;
                #endif
        }
        color = blurred / dofSteps;
    }
    
    // close up blur
    else if (currentDepth <= centerDepthSmooth) {
        vec3 blurred = vec3(0.0);
        float blurSize = clamp((centerDepthSmooth-currentDepth)*(256.0*APERTURE), 0.0, (12.0*APERTURE));
        for (int i = 0; i <= dofSteps; i++) {
                vec2 offset = poissonDisk[i] * oneTexel * blurSize;
                #ifdef CHROM_ABB
                float b = texture2D(colortex0, texcoord + offset + vec2(blurSize * oneTexel.x, 0.0)).b;
                vec2 rg = texture2D(colortex0, texcoord + offset).rg;
                blurred += vec3(rg, b);
                #else
                blurred += texture2D(colortex0, texcoord + offset).rgb;
                #endif
        }
        color = blurred / dofSteps;
    }
    #endif

    #ifdef BLOOM
    vec3 bloomSample = color.rgb * clamp01(pow(luma(color.rgb), 4.0));
    bloomOut = vec4(bloomSample, 1.0);
    #endif

    colorOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif