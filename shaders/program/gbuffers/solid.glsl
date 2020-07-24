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
layout (location = 2) out vec4 normalOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;
in float id;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;
uniform sampler2D specular;

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

    // emissives handling

    if      (idCorrected == 50 )  albedo.rgb *= clamp01(pow(luminance, 6))*60.0;
    else if (idCorrected == 51 )  albedo.rgb *= clamp01(pow(luminance, 6))*75.0;
    else if (idCorrected == 83 )  albedo.rgb *= clamp01(pow(luminance, 8))*62.5;
    else if (idCorrected == 100)  albedo.rgb *= clamp01(pow(luminance, 8))*100.0;
    else if (idCorrected == 105)  albedo.rgb *= clamp01(pow(luminance, 4))*100.0;
    else if (idCorrected == 110)  albedo.rgb *= clamp01(pow(luminance, 8))*50.0;
    else if (idCorrected == 120)  albedo.rgb *= 25;
    else if (idCorrected == 122)  albedo.rgb *= 12.5;

    // get specular
    vec4 specularData = texture2D(specular, texcoord);

    // get material mask

    int matMask = 0;

    if (idCorrected == 20 || idCorrected == 21 || idCorrected == 23) {
        matMask = 1;
    }

    // output everything
	albedoOut = albedo;
    dataOut = vec4(
        encodeLightmaps(lmcoord), // lightmap
        matMask/10.0, // material mask
        albedo.a, // albedo alpha
        encodeSpecular(specularData.rgb) // specular
    );
    normalOut = vec4(normal, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec2 lmcoord;
out vec3 normal;
out float id;
out vec4 glcolor;

// Uniforms
attribute vec3 mc_Entity;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    id = mc_Entity.x;

    glcolor = gl_Color;

    gl_Position = ftransform();
}

#endif