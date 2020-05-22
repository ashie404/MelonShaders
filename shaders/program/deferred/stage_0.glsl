/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:05 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 reflectionsOut;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 shadowLightPosition;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/shading.glsl"
#include "/lib/noise.glsl"
#include "/lib/atmosphere.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
    viewPos /= viewPos.w;
    vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;

    // if sky, draw sky. else, calculate shading.
    if (texture2D(depthtex0, texcoord).r == 1.0) {
        color = getSkyColor(worldPos, normalize(worldPos), mat3(gbufferModelViewInverse) * normalize(shadowLightPosition), sunAngle);
    } else {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);

        // lightmap filtering
        #ifdef FILTER_LIGHTMAP
        vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight)*8;
        vec2 lightmap = vec2(0, 0);
        float baseDepth = texture2D(depthtex0, texcoord).r;
        for (int x = -4; x <= 4; x++) {
            for (int y = -4; y <= 4; y++) {
                vec2 offset = vec2(x, y) * texelSize;
                float currentDepth = texture2D(depthtex0, texcoord + offset).r;
                if (currentDepth >= baseDepth-0.0005 && currentDepth <= baseDepth+0.0005) {
                    lightmap += texture2D(colortex1, texcoord + offset).xy;
                } else {
                    lightmap += texture2D(colortex1, texcoord).xy;
                }
            }
        }
        frag.lightmap = lightmap / 64;
        #endif

        vec4 pos = vec4(vec3(texcoord, texture2D(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);
        pos = gbufferProjectionInverse * pos;
        pos = gbufferModelViewInverse * pos;
        pos = shadowModelView * pos;
        pos = shadowProjection * pos;
        pos /= pos.w;
        vec3 shadowPos = distort(pos.xyz) * 0.5 + 0.5;

        color = calculateShading(frag, pbr, normalize(viewPos.xyz), shadowPos);
        #ifdef LIGHTMAP_DEBUG
        color = vec3(frag.lightmap, 0.0);
        #endif
        reflectionsOut = vec4(color, 1.0);
    }
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