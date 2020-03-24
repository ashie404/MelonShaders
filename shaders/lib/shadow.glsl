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

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap, in vec4 shadowPos, in vec3 viewVec, in float smoothness, in float F0) {
    // blocklight
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.05;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    // skylight
    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    // sunlight
    vec4 sunLight = getShadows(frag.coord, shadowPos.xyz);

    // diffuse uses roughness instead of perceptual smoothness, so convert smoothness to roughness. also helpful when calculating reflections
    float roughness = pow(1 - smoothness, 2);

    // oren-nayar diffuse
    float diffuseStrength = OrenNayar(normalize(viewVec),normalize(lightVector) , normalize(frag.normal), roughness);
    vec3 diffuseLight = diffuseStrength * lightColor;
    diffuseLight = max(skyColor*16, diffuseLight);

    #ifdef SPECULAR
    // ggx specular
    float specularStrength = GGX(normalize(frag.normal), normalize(viewVec), normalize(lightVector), smoothness, F0, 0.5);
    vec3 specularLight = specularStrength * lightColor;
    // screen space reflections if surface is smooth enough
    #ifdef SCREENSPACE_REFLECTIONS
    if (roughness <= 0.25) {
        // bayer64 dither
        float dither = bayer64(gl_FragCoord.xy);
        // calculate ssr color
        vec4 reflection = reflection(viewVec,frag.normal,dither,gcolor);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));

        specularLight *= mix(specularLight, reflection.rgb, reflection.a);
    } 
    #endif
    #endif

    // calculate all light sources together except for blocklight
    vec3 allLight = sunLight.rgb + skyLight;

    vec3 color = diffuseLight*allLight;

    // if non-shadowed, calculate specular reflections
    #ifdef SPECULAR
    if (isNight == 0) {
        if (sunLight.a > 0.5) {
            color += specularLight*allLight;
        }
    } else {
        if (sunLight.a > 0.1) {
            color += specularLight*allLight;
        }
    }
    #endif
    
    // add blocklight
    color += blockLight;

    // multiply by albedo to get final color
    color *= frag.albedo;

    return color;

}