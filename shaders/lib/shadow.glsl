uniform sampler2D shadowtex1;

#include "/lib/ggx.glsl"
#include "/lib/diffuse.glsl"

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

vec4 getShadows(in vec2 coord, in vec3 shadowPos)
{
    vec3 shadowCol = vec3(0.0); // shadow color
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    if (texture2D(depthtex0, coord).r < 1) // if not sky, calculate shadows
    {
        float visibility = 0;
        for (int y = -2; y < 2; y++) {
            for (int x = -2; x < 2; x++) {
                vec2 offset = vec2(x, y) / shadowMapResolution;
                offset = rotationMatrix * offset;
                // sample shadow map and shadow color
                float shadowMapSample = texture2D(shadowtex0, shadowPos.xy + offset).r; // sampling shadow map
                visibility += step(shadowPos.z - shadowMapSample, 0.001);
                vec3 colorSample = texture2D(shadowcolor0, shadowPos.xy + offset).rgb; // sample shadow color
                shadowCol += mix (colorSample, lightColor, visibility) * 1.2;
            }
        }
        return vec4(shadowCol / 256, visibility);
    }
    else
    {
        return vec4(0.35,0.15,0.15, 1);
    }
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap, in vec4 shadowPos, in vec3 viewVec, in float roughness, in float F0) {
    /*vec4 sunLight = getShadows(frag.coord, shadowPos.xyz);
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.07;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    // burley diffuse
    float diffuseStrength = Burley(normalize(frag.normal), normalize(viewVec), normalize(lightVector), roughness);
    diffuseStrength = max(0.15, diffuseStrength);
    vec3 diffuseLight = (diffuseStrength) * skyColor;

    // ggx specular
    float specularStrength = GGX(normalize(frag.normal), normalize(viewVec), normalize(lightVector), roughness, F0, 0.5);
    vec3 specularLight = frag.albedo * ((specularStrength) * (lightColor));

    vec3 color = frag.albedo * (sunLight.rgb);
    
    // if there is no shadow cast, or the block light is bright enough, add specular highlights and diffuse light
    if (sunLight.a > 0.5 || lightmap.blockLightStrength > 0.5) {
        color *= frag.albedo * diffuseLight;
        color += frag.albedo * specularLight;
    }

    color += frag.albedo * ((sunLight.rgb / 10) + skyLight + blockLight);

    if (frag.emission == 1) {
        return frag.albedo;
    }
    else {
        return color;
    }*/

    // blocklight
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.04;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    // skylight
    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    // sunlight
    vec4 sunLight = getShadows(frag.coord, shadowPos.xyz);
    //sunLight.rgb *= skyColor;

    // oren-nayar diffuse
    float diffuseStrength = OrenNayar(normalize(viewVec),normalize(shadowLightPosition) , normalize(frag.normal), roughness);
    vec3 diffuseLight = diffuseStrength * lightColor;
    diffuseLight = max(skyColor*16, diffuseLight);

    // ggx specular
    float specularStrength = GGX(normalize(frag.normal), normalize(viewVec), normalize(shadowLightPosition), roughness, F0, 0.5);
    vec3 specularLight = specularStrength * lightColor;

    vec3 color = vec3(0);

    vec3 fSunLight = sunLight.rgb + skyLight + blockLight;

    color = diffuseLight*fSunLight;

    if (sunLight.a > 0.3) {
       color += specularLight*fSunLight;
    }

    color *= frag.albedo;

    return vec3(color);

}

// basic lighting (no shadowmap)
vec3 calculateBasicLighting(in Fragment frag, in Lightmap lightmap, in vec3 viewVec) {
    //float directLightStrength = dot(frag.normal, lightVector);
    //directLightStrength = max(0.2, directLightStrength);
    float directLightStrength = GGX(frag.normal, viewVec, lightVector, 0.5, 0, 0.5);
    directLightStrength = max(0, directLightStrength);
    vec3 directLight = directLightStrength * lightColor*2;
    
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.07;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    vec3 color = frag.albedo * (directLight + skyLight + blockLight);

    if (frag.emission == 1) {
        return frag.albedo;
    }
    else {
        return color;
    }
}
