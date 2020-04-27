/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0123 */
layout (location = 0) out vec4 albedoOut; // albedo output
layout (location = 1) out vec4 lmMatOut; // lightmap and material mask output
layout (location = 2) out vec4 normalOut; // normal output
layout (location = 3) out vec4 specularOut; // specular output

// uniforms
uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;

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

    int correctedId = int(id + 0.5);

    vec4 albedo = texture2D(texture, texcoord);
    float luminance = luma(albedo);
    albedo *= glcolor;
    albedo.rgb = toLinear(albedo.rgb);
    // emissive handling
    if (correctedId == 50)  if (luminance >= 0.65)  albedo.rgb *= 70;
    if (correctedId == 60)  if (luminance >= 0.35)  albedo.rgb *= 100;
    if (correctedId == 70)  if (luminance >= 0.45)  albedo.rgb *= 75;
    if (correctedId == 80)  if (luminance >= 0.50)  albedo.rgb *= 200;
    if (correctedId == 90)  if (luminance >= 0.50)  albedo.rgb *= 100;
    if (correctedId == 100) if (luminance >= 0.70)  albedo.rgb *= 25;
    if (correctedId == 110) if (luminance >= 0.65)  albedo.rgb *= 75;
    if (correctedId == 120) albedo.rgb *= 50;

    // get lightmap

    // correct floating point precision errors
    
    float matMask = 0.0;
    // subsurf scattering id is 20
    if (correctedId == 20) {
        matMask = 1.0;
    }
    
    // get normals

    vec3 normalData = getTangentNormals(texcoord).xyz;
    normalData = normalize(normalData * tbn);
    
    // get specular

    vec4 specularData = texture2D(specular, texcoord);

    // output everything

    albedoOut = albedo;
    lmMatOut = vec4(lmcoord.xy, 0.0, matMask);
    normalOut = vec4(normalData * 0.5 + 0.5, 1.0);
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
attribute vec3 mc_Entity;
attribute vec4 at_tangent;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    id = mc_Entity.x;

    vec3 normal   = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent  = normalize(gl_NormalMatrix * (at_tangent.xyz));
    tbn = transpose(mat3(tangent, normalize(cross(tangent, normal)), normal));
}

#endif