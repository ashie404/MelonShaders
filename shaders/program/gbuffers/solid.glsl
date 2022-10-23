/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0,1,4,5 */
out vec4 albedoOut;
out vec4 dataOut;
out vec4 normalOut;
out vec4 aoOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;
in mat3 tbn;
in float id;
in vec4 glcolor;
in vec4 worldSpace;

// Uniforms
uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;

uniform int entityId;

uniform float rainStrength;
uniform float sunAngle;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

// Includes
#include "/lib/util/noise.glsl"
#include "/lib/fragment/dirLightmap.glsl"

void calculateHardcodedEmissives(in int id, in float luminance, in float emissionMult, inout vec3 albedo) {
    switch (id) {
    case 11 : albedo *= max(7.5*emissionMult, 1.0); break;
    case 42 : albedo *= max(clamp01(pow(luminance, 6))* 60.0*emissionMult, 1.0); break;
    case 50 : albedo *= max(clamp01(pow(luminance, 6))* 60.0*emissionMult, 1.0); break;
    case 51 : albedo *= max(clamp01(pow(luminance, 6))* 75.0*emissionMult, 1.0); break;
    case 83 : albedo *= max(clamp01(pow(luminance, 8))* 62.5*emissionMult, 1.0); break;
    case 100: albedo *= max(clamp01(pow(luminance, 8))*100.0*emissionMult, 1.0); break;
    case 105: albedo *= max(clamp01(pow(luminance, 4))*100.0*emissionMult, 1.0); break;
    case 110: albedo *= max(clamp01(pow(luminance, 8))* 50.0*emissionMult, 1.0); break;
    case 120: albedo *= max(25.0*emissionMult, 1.0); break;
    case 122: albedo *= max(12.5*emissionMult, 1.0); break;
    case 132: albedo *= max(luminance*(1000.0*clamp(1.0-lmcoord.y, 0.05, 0.6))*emissionMult, 1.0); break;
    }
}

void main() {

    int idCorrected = int(id + 0.5);

    // get albedo
    vec4 albedo = texture2D(texture, texcoord);
    albedo.rgb *= glcolor.rgb;

    if (albedo.a < 0.1) {
        discard;
    }

    float luminance = luma(albedo.rgb);

    albedo.rgb = toLinear(albedo.rgb);

    // get specular
    vec4 specularData = texture2DLod(specular, texcoord, 0.0);

    #ifndef NO_PUDDLES
    #ifdef RAIN_PUDDLES
    if (rainStrength > 0.0 && lmcoord.y > 0.25) {
        vec3 worldPos = worldSpace.xyz+cameraPosition;
        #ifdef STRETCH_PUDDLES_Y
        worldPos.y = 0.0;
        #endif
        float puddles = clamp01(cellular(worldPos/16.0)*PUDDLE_MULT);

        #ifdef POROSITY
        if (specularData.b <= 0.251 && EMISSIVE_MAP != 1) {
            albedo.rgb = mix(albedo.rgb, pow(albedo.rgb, mix(vec3(1.0), vec3(2.25), clamp01((specularData.b/0.251)*puddles))), rainStrength);
            specularData.r = mix(specularData.r, mix(clamp01(specularData.r+puddles), specularData.r, specularData.b/0.251), rainStrength);
        } else {
            specularData.r = mix(specularData.r, clamp01(specularData.r+puddles), rainStrength);
        }
        #else
        specularData.r = mix(specularData.r, clamp01(specularData.r+puddles), rainStrength);
        #endif

        specularData.r = clamp01(specularData.r);
    }
    #endif
    #endif

    // emissives handling

    #if WORLD == 0
    float night = ((clamp(sunAngle, 0.50, 0.53)-0.50) / 0.03 - (clamp(sunAngle, 0.96, 1.00)-0.96) / 0.03);
    float emissionMult = mix(0.15, 1.5, clamp01(night+clamp01(1.0-lmcoord.y)))*EMISSIVE_STRENGTH;
    #elif WORLD == -1
    float emissionMult = EMISSIVE_STRENGTH;
    #elif WORLD == 1
    float emissionMult = EMISSIVE_STRENGTH;
    #endif

    #if EMISSIVE_MAP == 0
        calculateHardcodedEmissives(idCorrected, luminance, emissionMult, albedo.rgb);
    #elif EMISSIVE_MAP == 1
        if (specularData.b > 0.0) albedo.rgb *= max(clamp(specularData.b * 15.0, 1.0, 15.0)*emissionMult, 1.0);
        #ifdef EMISSIVE_FALLBACK
        vec3 hardcoded = albedo.rgb;
        calculateHardcodedEmissives(idCorrected, luminance, emissionMult, hardcoded);
        albedo.rgb = mix(hardcoded, albedo.rgb, specularData.b);
        #endif
    #elif EMISSIVE_MAP == 2
        if (specularData.a < 1.0) albedo.rgb *= max(clamp(specularData.a * 15.0, 1.0, 15.0)*emissionMult, 1.0);
        #ifdef EMISSIVE_FALLBACK
        vec3 hardcoded = albedo.rgb;
        calculateHardcodedEmissives(idCorrected, luminance, emissionMult, hardcoded);
        albedo.rgb = mix(hardcoded, albedo.rgb, specularData.a < 1.0 ? specularData.a : 0.0);
        #endif
    #endif

    #ifdef SPIDEREYES
    albedo.rgb *= 500.0*emissionMult;
    #endif

    // get normal map
    vec3 normalData = vec3(texture2D(normals, texcoord).xy, 0.0) * 2.0 - 1.0;
    if (all(equal(normalData, vec3(0.0)))) {
        // invalid normal, reset to default normal
        normalData = normal;
    } else {
        #ifdef REBUILD_Z
        normalData.z = sqrt(clamp01(1.0 - dot(normalData.xy, normalData.xy)));
        #endif
        normalData = normalize(normalData * tbn);
    }

    

    #ifdef DIRECTIONAL_LIGHTMAP
    vec2 lm = lmcoord.xy;

    mat3 lmtbn = getLightmapTBN((gbufferModelView * worldSpace).xyz);

    lm.x = directionalLightmap(clamp01(lm.x), lm.x, normalData, lmtbn);
    lm.y = directionalLightmap(clamp01(lm.y), lm.y, normalData, lmtbn);
    #else
    vec2 lm = lmcoord.xy;
    #endif
    

    // get material mask

    int matMask = 0;

    if (idCorrected == 20 || idCorrected == 21 || idCorrected == 23 || idCorrected == 42) {
        matMask = 1;
    } else if (entityId == 7) {
        albedo.rgb = vec3(15.0*emissionMult);
        matMask = 4;
    }

    // output everything
	albedoOut = albedo;
    dataOut = vec4(
        encodeLightmaps(clamp01(lm-0.03125)), // lightmap
        encodeLightmaps(vec2(matMask/10.0, albedo.a)), // material mask and albedo alpha
        specularData.g, // specular green channel
        specularData.r // specular red channel
    );
    normalOut = vec4((mat3(gbufferModelViewInverse) * normalData) * 0.5 + 0.5, encodeColor(toSrgb(albedo.rgb)));
    #ifndef RTAO
    aoOut = vec4(vec3(glcolor.a), 1.0);
    #endif
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec2 lmcoord;
out vec3 normal;
out vec4 worldSpace;
out mat3 tbn;
out float id;
out vec4 glcolor;

// Uniforms
attribute vec3 mc_Entity;
attribute vec3 mc_midTexCoord;
attribute vec4 at_tangent;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

// Includes
#include "/lib/util/noise.glsl"
#include "/lib/util/taaJitter.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = gl_NormalMatrix * (at_tangent.xyz / at_tangent.w);
    tbn = transpose(mat3(tangent, cross(tangent, normal), normal));

    id = mc_Entity.x;

    glcolor = gl_Color;

    gl_Position = ftransform();
    worldSpace = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

    #ifdef WIND
    if ((mc_Entity.x == 20.0 && gl_MultiTexCoord0.t < mc_midTexCoord.t) || mc_Entity.x == 21.0) {
        vec4 position = worldSpace;
        position.x += (sin((frameTimeCounter*2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
        position.z += (sin((frameTimeCounter/2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    #endif
    #ifdef WAVY_LAVA
    if (mc_Entity.x == 11.0) {
        vec4 position = worldSpace;
        position.y += (sin(frameTimeCounter+cellular(position.xyz+cameraPosition+(frameTimeCounter/16.0))*4.0)/24.0);
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }   
    #endif

    #ifdef TAA
    gl_Position.xy += jitter(2.0)*gl_Position.w;
    #endif
}

#endif