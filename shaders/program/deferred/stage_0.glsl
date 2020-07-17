/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:05 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 noTranslucentsOut;

/*
const float eyeBrightnessSmoothHalflife = 4.0;
*/

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
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform int frameCounter;
uniform int isEyeInWater;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjection;
uniform ivec2 eyeBrightnessSmooth;

uniform float viewWidth;
uniform float viewHeight;
uniform float far, near;
uniform float aspectRatio;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform vec3 fogColor;

in vec2 texcoord;
in vec3 ambientColor;
in vec3 lightColor;
in vec4 times;

#define linear(x) (2.0 * near) / (far + near - x * (far - near))

#include "/lib/distort.glsl"
#include "/lib/fragmentUtil.glsl"
#include "/lib/labpbr.glsl"
#include "/lib/poisson.glsl"
#include "/lib/shading.glsl"
#include "/lib/noise.glsl"
#include "/lib/atmosphere.glsl"

#include "/lib/ssao.glsl"

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;

    float depth0 = texture2D(depthtex0, texcoord).r;
    float depth1 = texture2D(depthtex1, texcoord).r;

    vec4 screenPos = vec4(vec3(texcoord, depth0) * 2.0 - 1.0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * screenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;

    bool shouldDrawFog = true;

    // if sky, draw sky. else, calculate shading.
    if (depth0 == 1.0) {
        #ifndef NETHER
        color = getSkyColor(worldPos.xyz, normalize(worldPos.xyz), mat3(gbufferModelViewInverse) * normalize(sunPosition), mat3(gbufferModelViewInverse) * normalize(moonPosition), sunAngle, false, true);
        #else
        color = fogColor*0.5;
        #endif
    } else {
        Fragment frag = getFragment(texcoord);
        PBRData pbr = getPBRData(frag.specular);

        float roughness = pow(1.0 - pbr.smoothness, 2.0);
        shouldDrawFog = (roughness <= 0.125 && frag.matMask != 3.0 && frag.matMask != 4.0) ? false : true;

        vec4 shadowPos = shadowModelView * worldPos;
        shadowPos = shadowProjection * shadowPos;
        shadowPos /= shadowPos.w;

        color = calculateShading(frag, pbr, normalize(viewPos.xyz), shadowPos.xyz);

        // calculate ssao
        float ao = AmbientOcclusion(depthtex0, bayer64(gl_FragCoord.xy));
        color *= mix(1.0, ao, 0.65);

    }
    
    if (isEyeInWater == 0 && shouldDrawFog) applyFog(viewPos.xyz, worldPos.xyz, depth0, color);

    colorOut = vec4(color, 1.0);
    noTranslucentsOut = vec4(color, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;
out vec3 ambientColor;
out vec3 lightColor;
out vec4 times;

uniform float sunAngle;
uniform float rainStrength;

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    calcLightingColor(sunAngle, rainStrength, sunPosition, shadowLightPosition, ambientColor, lightColor, times);
}

#endif