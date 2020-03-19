uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;

uniform sampler2D colortex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;
uniform sampler2D colortex7;

uniform float viewWidth;
uniform float viewHeight;

float depth = 0.5;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

vec4 getCameraPosition(in vec2 coord) {
    float getdepth = depth;
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * getdepth - 1.0, 1.0);
    vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;

    return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePosition(in vec2 coord) {
    vec4 cameraPos = getCameraPosition(coord);
    vec4 worldPos = gbufferModelViewInverse * cameraPos;
    worldPos.xyz += cameraPosition;

    return worldPos;
}

vec3 getShadowSpacePosition(in vec2 coord)
{
    vec4 worldSpacePos = getWorldSpacePosition(coord);
    worldSpacePos.xyz -= cameraPosition;

    vec4 shadowSpacePos = shadowModelView * worldSpacePos;
    shadowSpacePos = shadowProjection * shadowSpacePos;

    return shadowSpacePos.xyz * 0.5 + 0.5;
}

mat2 getRotationMatrix(in vec2 coord) {
    float rotationAmount = texture2D(
        noisetex,
        coord * vec2(
            viewWidth / noiseTextureResolution,
            viewHeight / noiseTextureResolution
        )
    ).r;
    return mat2(
        cos(rotationAmount), -sin(rotationAmount),
        sin(rotationAmount), cos(rotationAmount)
    );
}



vec3 getShadows(in vec2 coord)
{
    vec3 shadowCoord = getShadowSpacePosition(coord); // shadow space position
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    vec3 shadowCol = vec3(0.0); // shadows var

    float visibility = 0;
    for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
            vec2 offset = vec2(x, y) / shadowMapResolution;
            offset = rotationMatrix * offset;
            float shadowMapSample = texture2D(shadowtex0, shadowCoord.st + offset).r; // sampling shadow map
            visibility += step(shadowCoord.z - shadowMapSample, 0.001);
            vec3 dayCol = vec3(1.0);
            vec3 colorSample = texture2D(shadowcolor0, shadowCoord.st + offset).rgb; // sample shadow color
            shadowCol += mix (colorSample, dayCol, visibility) * 1.2;
        }
    }

    return vec3(shadowCol) / 32;
}

vec3 calculateLighting(in vec3 color) {
    vec3 sunLight = getShadows(texcoord.st);
    vec3 ambientLight = vec3(0.5, 0.7, 1.0);

    return color * (sunLight + ambientLight);
}