/*
    Melon Shaders by June
    https://juniebyte.cf
*/

// rotation matrix for soft shadows
mat2 getRotationMatrix(in vec2 coord) {
    float rotationAmount = texture2D(
        noisetex,
        coord * vec2(
            viewWidth / noiseTextureResolution,
            viewHeight / noiseTextureResolution
        )
    ).r;
    rotationAmount = fract(frameTimeCounter * 4.0 + rotationAmount);
    return mat2(
        cos(rotationAmount), -sin(rotationAmount),
        sin(rotationAmount), cos(rotationAmount)
    );
}

float getBlockerDepth(in vec2 coord, in vec3 unDisShadowPos) {
    mat2 rotationMatrix = getRotationMatrix(coord);

    float blockerDepth = 0.0;
    int blockers = 0;

    for (int i = 0; i <= 8; i++) {
        vec2 offset = (poissonDisk[i]*8.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
        offset = rotationMatrix * offset;

        vec3 shadowPos = distort(vec3(unDisShadowPos.xy + offset, unDisShadowPos.z)) * 0.5 + 0.5;
        
        float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r;

        if (shadowMapSample < shadowPos.z) {
            blockerDepth += shadowPos.z - shadowMapSample;
            blockers++;
        }
    }

    return blockerDepth / blockers;
}

// shadowmap sampling
vec4 getShadows(in vec2 coord, in vec3 unDisShadowPos)
{
    vec3 shadowCol = vec3(0.0); // shadow color
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    float visibility = 0;

    #ifdef PCSS
    float blockerDepth = getBlockerDepth(coord, unDisShadowPos);
    float softness = clamp01(blockerDepth)*80.0;
    #endif

    for (int i = 0; i <= 16; i++) {
        #ifdef PCSS
        vec2 offset = (poissonDisk[i]*softness*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #else
        vec2 offset = (poissonDisk[i]*SHADOW_SOFTNESS*0.5*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #endif
        offset = rotationMatrix * offset;

        // sample shadow map
        vec3 shadowPos = distort(vec3(unDisShadowPos.xy + offset, unDisShadowPos.z)) * 0.5 + 0.5;
        float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r; // sampling shadow map

        visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
        
        // check if shadow color should be sampled, if yes, sample and add colored shadow, if no, just add the shadow map sample
        if (shadowMapSample < texture2D(shadowtex1, shadowPos.xy).r) {
            vec3 colorSample = texture2D(shadowcolor0, shadowPos.xy).rgb; // sample shadow color
            shadowCol += colorSample*2.0;
        } else {
            shadowCol += mix(vec3(shadowMapSample), vec3(1.0), visibility);
        }
    }
    return vec4(shadowCol / 128, visibility);
}

// diffuse shading
float OrenNayar(vec3 v, vec3 l, vec3 n, float r) {
    
    r *= r;
    
    float NdotL = dot(n,l);
    float NdotV = dot(n,v);
    
    float t = max(NdotL,NdotV);
    float g = max(.0, dot(v - n * NdotV, l - n * NdotL));
    float c = g/t - g*t;
    
    float a = .285 / (r+.57) + .5;
    float b = .45 * r / (r+.09);

    return max(0., NdotL) * ( b * c + a);

}

// specular shading
float ggx(vec3 normal, vec3 svec, vec3 lvec, PBRData pbrData) {
    float f0  = pbrData.F0;
    float roughness = pow(1.0 - pbrData.smoothness, 2.0);

    vec3 h      = lvec - svec;
    float hn    = inversesqrt(dot(h, h));
    float hDotL = clamp01(dot(h, lvec)*hn);
    float hDotN = clamp01(dot(h, normal)*hn);
    float nDotL = clamp01(dot(normal, lvec));
    float denom = (hDotN * roughness - hDotN) * hDotN + 1.0;
    float D     = roughness / (PI * denom * denom);
    float F     = f0 + (1.0-f0) * exp2((-5.55473*hDotL-6.98316)*hDotL);
    float k2    = 0.25 * roughness;

    return nDotL * D * F / (hDotL * hDotL * (1.0-k2) + k2);
}

// shading calculation
vec3 calculateShading(in Fragment fragment, in PBRData pbrData, in vec3 viewVec, in vec3 undistortedShadowPos) {

    // calculate skylight
    vec3 skyLight = ambientColor * fragment.lightmap.y;

    // calculate blocklight
    vec3 blockLightColor = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)*BLOCKLIGHT_I;
    vec3 blockLight = blockLightColor * pow(fragment.lightmap.x, 4);

    #ifdef NETHER

    vec3 color = vec3(0.81, 0.5, 0.49)*0.25;
    color += blockLight;

    #else

    // calculate diffuse lighting
    float diffuseStrength = OrenNayar(normalize(viewVec), normalize(shadowLightPosition), normalize(fragment.normal), pow(1.0 - pbrData.smoothness, 2.0));
    vec3 diffuseLight = diffuseStrength * lightColor;

    // calculate shadows
    vec4 shadowLight = getShadows(fragment.coord, undistortedShadowPos);

    // combine lighting
    vec3 color = vec3(0.0);
    if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
        color = mix(shadowLight.rgb+vec3(0.001)+blockLight, (shadowLight.rgb*diffuseLight)+skyLight+blockLight, clamp01((eyeBrightnessSmooth.y-9)/55.0));
    } else if (eyeBrightnessSmooth.y <= 8) {
        color = shadowLight.rgb+vec3(0.001)+blockLight;
    } else {
        color = (shadowLight.rgb*diffuseLight)+skyLight+blockLight;
    }
    

    // 1 on matmask is hardcoded SSS
    #ifdef SSS
    if (fragment.matMask == 1) {
        float depth = length(viewVec);
        float visibility = shadowLight.a;

        mat2 rotationMatrix = getRotationMatrix(fragment.coord);

        for (int i = 0; i <= 4; i++) {
            vec2 offset = (poissonDisk[i]*16.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
            offset = rotationMatrix * offset;
            // sample shadow map
            vec3 shadowPos = distort(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
            float shadowMapSample = texture2D(shadowtex0, shadowPos.xy + offset).r;
            visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
        }

        float strength = 1.0-(depth-(visibility/8));
        vec3 subsurfColor = mix(vec3(0), lightColor/2.0, clamp01(strength))*SSS_STRENGTH;
        color += subsurfColor;
    }
    #endif

    #ifdef SPECULAR
    // calculate specular highlights if non-shadowed
    
    if (shadowLight.a > 0.1) {
        float specularStrength = ggx(normalize(fragment.normal), normalize(viewVec), normalize(shadowLightPosition), pbrData);
        vec3 specularHighlight = specularStrength * lightColor;
        color += mix(vec3(0.0), specularHighlight, clamp01(shadowLight.a));
    }
    #endif

    #endif

    // multiply by albedo to get final color
    #ifndef WHITEWORLD
    color *= fragment.albedo.rgb;
    #endif

    return color;
}

vec3 calculateTranslucentShading(in Fragment fragment, in PBRData pbrData, in vec3 viewVec, in vec3 undistortedShadowPos, in float alpha) {
    // calculate skylight
    vec3 skyLight = ambientColor * fragment.lightmap.y;

    // calculate blocklight
    vec3 blockLightColor = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)*BLOCKLIGHT_I;
    vec3 blockLight = blockLightColor * pow(fragment.lightmap.x, 4);

    #ifdef NETHER

    vec3 color = fogColor*0.05;//vec3(0.81, 0.5, 0.49)*0.25;
    color += blockLight;

    #else

    // calculate diffuse lighting
    float diffuseStrength = OrenNayar(normalize(viewVec), normalize(shadowLightPosition), normalize(fragment.normal), pow(1.0 - pbrData.smoothness, 2.0));
    vec3 diffuseLight = diffuseStrength * lightColor;

    // calculate shadows
    vec4 shadowLight = getShadows(fragment.coord, undistortedShadowPos);

    // combine lighting
    vec3 color = vec3(0.0);
    if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
        color = mix(shadowLight.rgb+vec3(0.001)+blockLight, (shadowLight.rgb*diffuseLight)+skyLight+blockLight, clamp01((eyeBrightnessSmooth.y-9)/55.0));
    } else if (eyeBrightnessSmooth.y <= 8) {
        color = shadowLight.rgb+vec3(0.001)+blockLight;
    } else {
        color = (shadowLight.rgb*diffuseLight)+skyLight+blockLight;
    }

    #ifdef SPECULAR
    // calculate specular highlights
    if (shadowLight.a > 0.1) {
        float specularStrength = ggx(normalize(fragment.normal), normalize(viewVec), normalize(shadowLightPosition), pbrData);
        vec3 specularHighlight = specularStrength * lightColor;
        color += specularHighlight;
    }
    #endif

    #endif

    // multiply by albedo to get final color
    color *= fragment.albedo.rgb;

    #ifdef TRANS_REFRACTION
    vec3 behind = vec3(0.0);
    vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

    #ifdef BLUR_TRANSLUCENT
    for (int i = 0; i <= 16; i++) {
        vec2 poffset = vec2(7.0*REFRACTION_STRENGTH) * (1.0-alpha);
        vec2 gboffset = (poissonDisk[i] + poffset) * oneTexel * (4.0*REFRACTION_STRENGTH);
        vec2 roffset = (poissonDisk[i+14] + poffset) * oneTexel * (5.0*REFRACTION_STRENGTH);
        vec3 temp = vec3(0.0, texture2D(colortex5, fragment.coord + gboffset).gb);
        temp.r = texture2D(colortex5, fragment.coord + roffset).r;
        behind += temp;
    }
    behind /= 16.0;
    #else
    vec2 poffset = vec2(7.0*REFRACTION_STRENGTH) * (1.0-alpha);
    vec2 gboffset = poffset * oneTexel * (4.0*REFRACTION_STRENGTH);
    vec2 roffset = poffset * oneTexel * (5.0*REFRACTION_STRENGTH);
    behind = vec3(0.0, texture2D(colortex5, fragment.coord + gboffset).gb);
    behind.r = texture2D(colortex5, fragment.coord + roffset).r;
    #endif

    #else
    vec3 behind = texture2D(colortex5, fragment.coord).rgb;
    #endif

    #ifdef WHITEWORLD
    color = vec3(1.0);
    #endif
    
    color = behind * mix(vec3(1.0), color, clamp01(alpha+0.5));

    return color;
}

