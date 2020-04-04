uniform sampler2D shadowtex1;

#include "/lib/BSDF.glsl"
#include "/lib/SSS.glsl"

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
    float visibility = 0;
    for (int y = -4; y < 4; y++) {
        for (int x = -4; x < 4; x++) {
            vec2 offset = vec2(x, y) / shadowMapResolution;
            offset = rotationMatrix * offset;
            // sample shadow map
            float shadowMapSample = texture2D(shadowtex0, shadowPos.xy + offset).r; // sampling shadow map
            visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
            
            // check if shadow color should be sampled, if yes, sample and add colored shadow, if no, just add the shadow map sample
            if (texture2D(shadowtex0, shadowPos.xy + offset).r < texture2D(shadowtex1, shadowPos.xy + offset).r ) {
                vec3 colorSample = texture2D(shadowcolor0, shadowPos.xy + offset).rgb; // sample shadow color
                shadowCol += mix (colorSample, lightColor, visibility) * 1.2;
            } else {
                shadowCol += mix(vec3(shadowMapSample), lightColor, visibility) * 1.2;
            }
        }
    }
    return vec4(shadowCol / 4096, visibility);
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap, in vec4 shadowPos, in vec3 viewVec, in PBRData pbrData) {
    // blocklight
    vec3 blockLightColor = vec3(1.0, 0.9, 0.8) * 0.005;
    vec3 blockLight = blockLightColor * lightmap.blockLightStrength;

    // skylight
    vec3 skyLight = skyColor * lightmap.skyLightStrength;

    // sunlight
    vec4 sunLight = getShadows(frag.coord, shadowPos.xyz);

    // diffuse uses roughness instead of perceptual smoothness, so convert smoothness to roughness. also helpful when calculating reflections
    float roughness = pow(1 - pbrData.smoothness, 2);

    // oren-nayar diffuse
    float diffuseStrength = OrenNayar(normalize(viewVec),normalize(lightVector) , normalize(frag.normal), roughness);
    vec3 diffuseLight = diffuseStrength * lightColor;

    #ifdef SPECULAR
    // ggx specular
    float specularStrength = ggx(normalize(frag.normal), normalize(viewVec), pbrData);
    vec3 specularLight = specularStrength * lightColor;
    #endif

    // calculate all light sources together except for blocklight
    vec3 allLight = sunLight.rgb + skyLight;

    vec3 color = (sunLight.rgb*diffuseLight)+skyLight;

    // calculate subsurface scattering if enabled
    #ifdef SSS

    // 0.3 emission is tag for sss
    if (frag.emission == 0.3) {
        float subsurfStrength = calcSSS(viewVec, frag.normal, lightVector);
        vec3 subsurfColor = mix(vec3(0), subsurfStrength * lightColor/128, sunLight.a)*SSS_STRENGTH;
        color += subsurfColor;
    }

    #endif

    // if non-shadowed, calculate specular reflections
    #ifdef SPECULAR
    if (isNight < 0.1) {
        if (sunLight.a > 0.3) {
            color += specularLight;
        }
    } else {
        if (sunLight.a > 0.1) {
            color += specularLight;
        }
    }
    #endif
    
    // add blocklight
    color += blockLight;

    // multiply by albedo to get final color
    color *= frag.albedo;

    return color;

}