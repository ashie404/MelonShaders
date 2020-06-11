/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:04 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 bloomOut;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float near;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;

#define linear(x) (2.0 * near * far / (far + near - (2.0 * x - 1.0) * (far - near)))

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/noise.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/poisson.glsl"
#include "/lib/shading.glsl"
#include "/lib/atmosphere.glsl"

#include "/lib/dither.glsl"
#include "/lib/raytrace.glsl"
#include "/lib/reflection.glsl"

/*
const bool colortex5MipmapEnabled = true;
*/

const vec3 attenuationCoefficient = vec3(1.0, 0.2, 0.1);
void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    vec4 screenPos = vec4(vec3(texcoord, texture2D(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos.xyz, 1.0)).xyz;
    
    // if not sky check for translucents
    if (texture2D(depthtex0, texcoord).r != 1.0) {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);
        // 2 is translucents tag
        if (frag.matMask == 2) {
            color = calculateBasicShading(frag, pbr, viewPos.xyz);
        }
        // 3 is water tag
        else if (frag.matMask == 3) {
            float depth0 = linear(texture2D(depthtex0, texcoord).r);
            float depth1 = linear(texture2D(depthtex1, texcoord).r);
    
            float depthcomp = (depth1-depth0);

            // set color to color without water in it
            vec3 oldcolor = color;
            color = texture2D(colortex5, texcoord).rgb;

            // if eye is not in water, render above-water fog and render sky reflection
            if (isEyeInWater == 0) {
                // calculate transmittance
                vec3 transmittance = exp(-attenuationCoefficient * depthcomp);

                color = color * transmittance;

                // colorize water fog based on biome color
                color *= oldcolor;

                vec3 reflectedPos = reflect(viewPos.xyz, frag.normal);
                vec3 reflectedPosWorld = (gbufferModelViewInverse * vec4(reflectedPos, 1.0)).xyz;

                vec3 skyReflection = getSkyColor(reflectedPosWorld, normalize(reflectedPosWorld), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle);

                #ifdef SSR
                vec4 reflectionColor = reflection(viewPos.xyz, frag.normal, bayer64(gl_FragCoord.xy), colortex5);
                color += mix(vec3(0.0), mix(mix(vec3(0.0), skyReflection, 0.25), reflectionColor.rgb, reflectionColor.a), 0.35)*frag.lightmap.y;
                #else
                color += mix(vec3(0.0), skyReflection, 0.05)*frag.lightmap.y;
                #endif

                // water foam
                if (depthcomp <= 0.15) {
		    	    color += vec3(0.75) * ambientColor;
		        } 
            }
        }
        #ifdef SSR
        #ifdef SPECULAR
        else {
            float roughness = pow(1.0 - pbr.smoothness, 2.0);
            if (roughness <= 0.15) {
                vec4 reflectionColor = roughReflection(viewPos.xyz, frag.normal, bayer64(gl_FragCoord.xy), roughness*6.6, colortex5);
                color *= mix(vec3(1.0), mix(vec3(1.0), reflectionColor.rgb, reflectionColor.a), 1.0-roughness*6.6);
            }
        }
        #endif
        #endif
    }
    // if eye in water, render underwater fog
    float depth = length(viewPos.xyz);
    if (isEyeInWater == 1) {
        color *= exp(-attenuationCoefficient * depth);
    } else {
        // apply actual fog if not underwater

    }

    

    #ifdef BLOOM
    // output bloom if pixel is bright enough
    vec3 bloomSample = vec3(0.0);
    if (luma(color) > 6.5) {
        bloomSample = color;
    }
    bloomOut = vec4(bloomSample, 1.0);
    #endif

    colorOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;
out vec3 ambientColor;
out vec3 lightColor;

uniform float sunAngle;
uniform float rainStrength;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    calcLightingColor(sunAngle, rainStrength, ambientColor, lightColor);
}

#endif