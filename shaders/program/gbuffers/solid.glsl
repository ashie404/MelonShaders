/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:014 */
layout (location = 0) out vec4 albedoOut;
layout (location = 1) out vec4 dataOut;
layout (location = 2) out vec3 normalOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;
in mat3 tbn;
in float id;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;
uniform float sunAngle;

uniform mat4 gbufferModelViewInverse;

// other stuff
vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

void main() {

    int idCorrected = int(id + 0.5);

    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    float luminance = luma(albedo.rgb);

    albedo.rgb = toLinear(albedo.rgb);

    // get specular
    vec4 specularData = texture2D(specular, texcoord);

    // emissives handling

    #if WORLD == 0
    float night = ((clamp(sunAngle, 0.50, 0.53)-0.50) / 0.03 - (clamp(sunAngle, 0.96, 1.00)-0.96) / 0.03);
    float emissionMult = mix(0.5, 1.5, night)*EMISSIVE_STRENGTH;
    #elif WORLD == -1
    float emissionMult = EMISSIVE_STRENGTH;
    #endif

    #if EMISSIVE_MAP == 0
        if      (idCorrected == 50 ) albedo.rgb *= clamp01(pow(luminance, 6))* 60.0*emissionMult;
        else if (idCorrected == 51 ) albedo.rgb *= clamp01(pow(luminance, 6))* 75.0*emissionMult;
        else if (idCorrected == 83 ) albedo.rgb *= clamp01(pow(luminance, 8))* 62.5*emissionMult;
        else if (idCorrected == 100) albedo.rgb *= clamp01(pow(luminance, 8))*100.0*emissionMult;
        else if (idCorrected == 105) albedo.rgb *= clamp01(pow(luminance, 4))*100.0*emissionMult;
        else if (idCorrected == 110) albedo.rgb *= clamp01(pow(luminance, 8))* 50.0*emissionMult;
        else if (idCorrected == 120) albedo.rgb *= 25*emissionMult;
        else if (idCorrected == 122) albedo.rgb *= 12.5*emissionMult;
    #elif EMISSIVE_MAP == 1
        if (specularData.b > 0.0) albedo.rgb *= clamp(specularData.b * 50.0, 1.0, 50.0)*emissionMult;
    #elif EMISSIVE_MAP == 2
        if (specularData.a < 1.0) albedo.rgb *= clamp(specularData.a * 50.0, 1.0, 50.0)*emissionMult;
    #endif

    #ifdef SPIDEREYES
    albedo.rgb *= 500.0*emissionMult;
    #endif

    // get normal map
    vec3 normalData = texture2D(normals, texcoord).xyz * 2.0 - 1.0;
    if (all(equal(normalData, vec3(0.0, 0.0, 0.0)))) {
        // invalid normal, reset to default normal
        normalData = normal;
    } else {
        #ifdef REBUILD_Z
        normalData.z = sqrt(clamp01(1.0 - dot(normalData.xy, normalData.xy)));
        #endif
        normalData = normalize(normalData * tbn);
    }
    

    // get material mask

    int matMask = 0;

    if (idCorrected == 20 || idCorrected == 21 || idCorrected == 23) {
        matMask = 1;
    }

    // output everything
	albedoOut = albedo;
    dataOut = vec4(
        encodeLightmaps(lmcoord), // lightmap
        encodeLightmaps(vec2(matMask/10.0, albedo.a)), // material mask and albedo alpha
        encodeLightmaps(specularData.gb), // specular green and blue channel
        specularData.r // specular red channel
    );
    normalOut = normalData * 0.5 + 0.5;
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec2 lmcoord;
out vec3 normal;
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

// Includes
#include "/lib/util/noise.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = gl_NormalMatrix * (at_tangent.xyz / at_tangent.w);
    tbn = transpose(mat3(tangent, cross(tangent, normal), normal));

    id = mc_Entity.x;

    glcolor = gl_Color;

    gl_Position = ftransform();

    #ifdef WIND
    if ((mc_Entity.x == 20.0 && gl_MultiTexCoord0.t < mc_midTexCoord.t) || mc_Entity.x == 21.0) {
        vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
        position.x += (sin((frameTimeCounter*2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
        position.z += (sin((frameTimeCounter/2.0*WIND_STRENGTH)+cellular(position.xyz+cameraPosition+(frameTimeCounter/8.0))*4.0)/12.0);
        gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    #endif
}

#endif