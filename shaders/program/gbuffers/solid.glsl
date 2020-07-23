/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 albedoOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;
in float id;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;


// Includes



// other stuff
vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

void main() {
    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    albedo.rgb = toLinear(albedo.rgb);

    int idCorrected = int(id + 0.5);

    // output everything
	albedoOut = albedo;
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

// Includes



void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    id = mc_Entity.x;

    glcolor = gl_Color;

    gl_Position = ftransform();
}

#endif