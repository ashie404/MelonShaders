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
in vec3 normal;
in vec4 glcolor;

// Uniforms
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
    // get albedo
    vec4 albedo = glcolor;

    albedo.rgb = toLinear(albedo.rgb);

    // output everything
	albedoOut = albedo;
    dataOut = vec4(
        encodeLightmaps(vec2(0.0, 1.0)), // lightmap
        0.0, // material mask
        1.0, // albedo alpha
        encodeSpecular(vec3(0.0)) // specular
    );
    normalOut = vec4(normal, 1.0);
}

#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec3 normal;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    normal = normalize(gl_NormalMatrix * gl_Normal);

    glcolor = gl_Color;

    gl_Position = ftransform();
}

#endif