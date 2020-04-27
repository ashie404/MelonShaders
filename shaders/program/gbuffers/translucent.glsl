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
in float waterWaves;

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
    // TODO: make emissives brighter

    // get lightmap

    // correct floating point precision errors
    int correctedId = int(id + 0.5);
    float matMask = 2.0;
    if (correctedId == 8) {
        matMask = 3.0;
        albedo = vec4(0.0, 0.0, 0.0, 0.25);
    }
    
    // get normals

    vec4 normalData = getTangentNormals(texcoord);
    //normalData.y -= waterWaves;
    normalData.xyz = normalize(normalData.xyz * tbn);
    
    // get specular

    vec4 specularData = texture2D(specular, texcoord);

    // output everything

    albedoOut = albedo;
    lmMatOut = vec4(lmcoord.xy, 0.0, matMask);
    normalOut = vec4(normalData.xyz * 0.5 + 0.5, 1.0);
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
out float waterWaves;

// uniforms
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;

attribute vec3 mc_Entity;
attribute vec4 at_tangent;

#include "/lib/noise.glsl"

float waves(vec2 pos, int iterations, int detail) {
    // this is just totally random code to create fancy waves
    float iter = 0.0;
    float finalWave = 0.0;
    float time = frameTimeCounter/512;
    vec2 position = pos/detail;
    for (int i=0; i<=iterations; i++) {
        float w1 = sin((pos.x+time)/-1.2)/WAVE_AMPLITUDE;
        float w2 = -abs(cos(pos.y)+time/-1.2)/WAVE_AMPLITUDE;
        float w3 = abs(sin(pos.x)+time/-1.2)/WAVE_AMPLITUDE;
        float w4 = -abs(sin(pos.y)+time/-1.2)/WAVE_AMPLITUDE*fbm2(pos.xyx+time);
        finalWave += w1+w2+w3+w4;
    }

    return finalWave/(iterations/detail)/128;
}

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
    id = mc_Entity.x;

    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = normalize(gl_NormalMatrix * (at_tangent.xyz));
    waterWaves = 0.0;
    // if water do fancy stuff for waves
    /*if (id == 8.0) {
        vec3 worldPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz + cameraPosition;

        waterWaves = waves(worldPos.xz, 48, 4);
        //normal.y -= waves;
        gl_Position.y -= waterWaves;
    }*/

    tbn = transpose(mat3(tangent, normalize(cross(tangent, normal)), normal));

    if (id == 8.0) {
        vec3 worldPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz + cameraPosition;

        waterWaves = waves(worldPos.xz, 48, 4);
        normal.y -= waterWaves;
        tbn = transpose(mat3(tangent, normalize(cross(tangent, normal)), normal));
        gl_Position.y -= waterWaves;
    }
}

#endif