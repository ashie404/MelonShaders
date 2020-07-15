/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:012 */
layout (location = 0) out vec4 albedoOut; // albedo output
layout (location = 1) out vec4 lmNormalMatOut; // lightmap, normal map, and material mask output
layout (location = 2) out vec4 specularOut; // specular output

// uniforms
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

// inputs from vertex
in float id;
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in mat3 tbn;

vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

vec4 getTangentNormals(vec2 coord) {
    vec4 normal = texture2D(normals, coord) * 2.0 - 1.0;
    return normal;
}

void main() {
    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;
    albedo.rgb = toLinear(albedo.rgb);

    // correct floating point precision errors
    int correctedId = int(id + 0.5);

    // determine material mask
    float matMask = 2.0;
    if (correctedId == 8) {
        matMask = 3.0;
        // return biome coloration in albedo
        albedo = vec4(glcolor.rgb, 1.0);
    } else if (correctedId == 9) {
        matMask = 3.0;
        albedo = vec4(0.1, 0.8, 0.1, 1.0);
    } else if (correctedId == 122) {
        albedo.rgb *= 15.0;
    }
    
    // get normals

    vec3 normalData = getTangentNormals(texcoord).xyz;
    normalData = normalize(normalData * tbn);
    
    // get specular

    vec4 specularData = texture2D(specular, texcoord);

    // output everything

    albedoOut = albedo;
    lmNormalMatOut = vec4(encodeLightmaps(clamp01(lmcoord.xy)), encodeNormals(normalData), matMask, albedo.a);
    specularOut = specularData;
}

#endif

// VERTEX SHADER //

#ifdef VERT

// outputs to fragment
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out mat3 tbn;
out float id;

// uniforms
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

attribute vec3 mc_Entity;
attribute vec4 at_tangent;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    id = mc_Entity.x;

    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = normalize(gl_NormalMatrix * (at_tangent.xyz));

    tbn = transpose(mat3(tangent, normalize(cross(tangent, normal)), normal));
}

#endif