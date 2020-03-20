float getDepth(in vec2 coord) {
    return texture2D(gdepthtex, coord).r;
}

vec4 getCameraSpacePosition(in vec2 coord) {
    float depth = getDepth(coord);
    vec4 positionNdcSpace = vec4(coord.s * 2.0 - 1.0, coord.t * 2.0 - 1.0, 2.0 * depth - 1.0, 1.0);

    vec4 positionCameraSpace = gbufferProjectionInverse * positionNdcSpace;
    return positionCameraSpace / positionCameraSpace.w;
}

vec4 getWorldSpacePosition(in vec2 coord) {
    vec4 positionCameraSpace = getCameraSpacePosition(coord);
    vec4 positionWorldSpace = gbufferModelViewInverse * positionCameraSpace;
    positionWorldSpace.xyz += cameraPosition.xyz;

    return positionWorldSpace;
}

vec3 getShadowSpacePosition(in vec2 coord) {
    vec4 positionWorldSpace = getWorldSpacePosition(coord);
    
    positionWorldSpace.xyz -= cameraPosition;
    vec4 positionShadowSpace = shadowModelView * positionWorldSpace;
    positionShadowSpace = shadowProjection * positionShadowSpace;
    positionShadowSpace /= positionShadowSpace.w;

    return positionShadowSpace.xyz * 0.5 + 0.5;
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
    if (texture2D(depthtex0, coord).r < 1) // if not sky, calculate shadows
    {
        float visibility = 0;
        for (int y = 0; y < 2; y++) {
            for (int x = 0; x < 2; x++) {
                vec2 offset = vec2(x, y) / shadowMapResolution;
                offset = rotationMatrix * offset;
                float shadowMapSample = texture2D(shadowtex0, shadowCoord.st + offset).r; // sampling shadow map
                visibility += step(shadowCoord.z - shadowMapSample, 0.001);
                vec3 colorSample = texture2D(shadowcolor0, shadowCoord.st + offset).rgb; // sample shadow color
                shadowCol += mix (colorSample, lightColor, visibility) * 1.2;
            }
        }

        return vec3(shadowCol) / 32;
    }
    else
    {
        return vec3(0.35,0.15,0.15);
    }
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap) {
    vec3 sunLight = getShadows(frag.coord);
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.1;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    vec3 color = frag.albedo * (sunLight + skyLight + blockLight);
    //color *= getSunVisibility(frag.coord);
    return mix(color, frag.albedo, frag.emission);
}
