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
in mat3 tbn;
in float id;
in vec4 glcolor;
in vec4 worldSpace;

// Uniforms
uniform sampler2D texture;
uniform sampler2D specular;
uniform sampler2D normals;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

uniform mat4 gbufferModelViewInverse;

// Includes
#include "/lib/util/noise.glsl"

// other stuff
vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

vec3 waterNormals(vec3 pos, float scale) {
    
  float height = cellular(pos);
    
  vec2 dxy = height - vec2(
      cellular(pos + vec3(1.0, 0.0, 0.0)), 
      cellular(pos + vec3(0.0, 0.0, 1.0))
  );
    
  return normalize(vec3(dxy * scale, 1.0));
}

void main() {

    int idCorrected = int(id + 0.5);

    // get albedo
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    albedo.rgb = toLinear(albedo.rgb);

    // get specular
    vec4 specularData = texture2DLod(specular, texcoord, 0.0);

    // get normal map
    vec3 normalData = texture2D(normals, texcoord).xyz * 2.0 - 1.0;
    if (all(equal(normalData, vec3(0.0)))) {
        // invalid normal, reset to default normal
        normalData = normal;
    } else {
        #ifdef REBUILD_Z
        normalData.z = sqrt(clamp01(1.0 - dot(normalData.xy, normalData.xy)));
        #endif
        normalData = normalize(normalData * tbn);
    }

    // get material mask

    int matMask = 2;

    if (idCorrected == 8) {
        matMask = 3;
        #ifdef WAVE_NORMALS
        // custom water normals
        vec3 worldPosCamera = worldSpace.xyz + cameraPosition;
        #ifdef WAVE_PIXEL
        worldPosCamera = vec3(ivec3(worldPosCamera*WAVE_PIXEL_R)/WAVE_PIXEL_R);
        #endif
        worldPosCamera.y += frameTimeCounter*WAVE_SPEED;

        normalData = normalize(waterNormals(worldPosCamera, WAVE_SCALE) * tbn);
        #else
        normalData = normal;
        #endif
    }

    // output everything
	albedoOut = albedo;
    dataOut = vec4(
        encodeLightmaps(clamp01(lmcoord-0.03125)), // lightmap
        encodeLightmaps(vec2(matMask/10.0, albedo.a)), // material mask and albedo alpha
        encodeLightmaps(specularData.gb), // specular green and blue channel
        specularData.r // specular red channel
    );
    normalOut = vec4((mat3(gbufferModelViewInverse) * normalData) * 0.5 + 0.5, encodeColor(albedo.rgb));
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
out vec4 worldSpace;

// Uniforms
attribute vec3 mc_Entity;
attribute vec4 at_tangent;

uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferModelViewInverse;

uniform int frameCounter;

// Includes
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

    #ifdef TAA
    gl_Position.xy += jitter(1.5+gl_Position.z);
    #endif
}

#endif