/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/



mat2 getRotationMatrix(in vec2 coord) {
    float rotationAmount = texelFetch(
        noisetex,
        ivec2(coord * ivec2(viewWidth, viewHeight)) & noiseTextureResolution-1,
        0
    ).r;
    rotationAmount = fract(frameTimeCounter * 4.0 + rotationAmount);
    return mat2(
        cos(rotationAmount), -sin(rotationAmount),
        sin(rotationAmount), cos(rotationAmount)
    );
}

float getBlockerDepth(in vec2 coord, in vec3 undistortedShadowPos) {
    mat2 rotationMatrix = getRotationMatrix(coord);

    float blockerDepth = 0.0;
    int blockers = 0;

    for (int i = 0; i <= 8; i++) {
        vec2 offset = (vogelDiskSample(i, 8, interleavedGradientNoise(gl_FragCoord.xy))*4.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
        offset = rotationMatrix * offset;

        vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
        
        float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r;

        if (shadowMapSample < shadowPos.z) {
            blockerDepth += shadowPos.z - shadowMapSample;
            blockers++;
        }
    }

    return blockerDepth / blockers;
}

// shadowmap sampling
vec4 getShadows(in vec2 coord, in vec3 viewPos, in vec3 undistortedShadowPos)
{
    vec3 shadowCol = vec3(0.0); // shadow color
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    float visibility = 0.0; // visibility
    float visibilityWT = 0.0; // visibility w/ translucents

    #ifdef PCSS
    float blockerDepth = clamp01(getBlockerDepth(coord, undistortedShadowPos));
    float softness = clamp(blockerDepth*80.0*SHADOW_SOFTNESS, 0.0, 4.0);
    #endif

    float shadowBias = getShadowBias(viewPos, sunAngle);

    for (int i = 0; i <= 16; i++) {
        
        #ifdef PCSS
        vec2 offset = (vogelDiskSample(i, 16, interleavedGradientNoise(gl_FragCoord.xy))*softness*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #else
        vec2 offset = (vogelDiskSample(i, 16, interleavedGradientNoise(gl_FragCoord.xy))*SHADOW_SOFTNESS*0.5*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #endif
        offset = rotationMatrix * offset;

        // sample shadow map
        vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;

        float shadowtex0Sample = texture2D(shadowtex0, shadowPos.xy).r;
        float shadowtex1Sample = texture2D(shadowtex1, shadowPos.xy).r;

        visibility += step(shadowPos.z - shadowtex1Sample, shadowBias);
        visibilityWT += step(shadowPos.z - shadowtex0Sample, shadowBias);
        
        if (visibilityWT < visibility) {
            vec3 colorSample = texture2D(shadowcolor0, shadowPos.xy).rgb; // sample shadow color
            shadowCol += colorSample*2.0;
        } else {
            shadowCol += mix(vec3(0.0), vec3(1.0), visibility);
        }
    }
    return vec4((shadowCol / 128.0), visibility);
}

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
float ggx(vec3 normal, vec3 svec, vec3 lvec, float f0, float smoothness) {
    float roughness = pow(1.0 - smoothness, 2.0);

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

vec3 getShadowsDiffuse(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos) {
    float diffuseStrength = OrenNayar(normalize(viewPos), normalize(shadowLightPosition), normalize(info.normal), 0.0);
    vec3 diffuseLight = vec3(diffuseStrength);

    vec4 shadowLight = diffuseStrength > 0.0 ? getShadows(info.coord, viewPos, undistortedShadowPos) : vec4(0.0);

    return min(diffuseLight, shadowLight.rgb);
}

vec3 calculateShading(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos, in bool aoMix) {
    // sky light & blocklight
    vec3 blockLightColor = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * 4.0 * BLOCKLIGHT_I;
    vec3 skyLight = mix(fogColor*0.5, vec3(luma(fogColor*0.5)), 0.5);

    vec3 ao = texture2D(colortex5, info.coord).rgb;

    #if WORLD == -1

    vec3 color = mix(skyLight*ao, blockLightColor, clamp01(pow(info.lightmap.x, 6.0*LIGHTMAP_STRENGTH)));

    #elif WORLD == 1

    vec3 color = mix(skyLight*ao, blockLightColor, clamp01(pow(info.lightmap.x, 6.0*LIGHTMAP_STRENGTH)));

    #elif WORLD == 0

    skyLight = aoMix ? ambientColor * ao * max(info.lightmap.y, 0.1) : ambientColor * max(info.lightmap.y, 0.1);

    vec3 shadowsDiffuse = getShadowsDiffuse(info, viewPos, undistortedShadowPos);

    // combine lighting
    vec3 color = (shadowsDiffuse*lightColor)+mix(skyLight, blockLightColor, clamp01(pow(info.lightmap.x, 6.0*LIGHTMAP_STRENGTH)));

    // subsurface scattering
    #ifdef SSS
    if (info.matMask == 1) {
        float depth = length(normalize(viewPos));
        float visibility = 0.0;

        mat2 rotationMatrix = getRotationMatrix(info.coord);

        float shadowBias = getShadowBias(viewPos, sunAngle);

        for (int i = 0; i <= 12; i++) {
            vec2 offset = (vogelDiskSample(i, 12, interleavedGradientNoise(gl_FragCoord.xy*frameCounter))*(12.0*SSS_SCATTER)*(shadowMapResolution/2048.0)) / shadowMapResolution;
            offset = rotationMatrix * offset;

            // sample shadow map
            vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
            float shadowMapSample = texture2D(shadowtex1, shadowPos.xy).r; // sampling shadow map

            visibility += step(shadowPos.z - shadowMapSample, shadowBias);
        }
        color += lightColor*clamp01(clamp01((visibility/4.0)-depth)/2.0);
    }
    #endif

    #endif

    // multiply by albedo to get final color
    #ifndef WHITEWORLD
    color *= info.albedo.rgb;
    #endif
    
    return color;
}

vec3 calculateTranslucentShading(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos) {

    #ifdef TRANS_MULT

    #ifdef FAKE_REFRACT
    vec3 behind = vec3(0.0);
    vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

    #ifdef BLUR_REFRACT

        for (int i = 0; i < 4; i++) {
            vec2 poffset = vec2(7.0*REFRACT_STRENGTH) * (1.0-info.albedo.a);
            vec2 gboffset = (vogelDiskSample(i, 4, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter)) + poffset) * oneTexel * (4.0*REFRACT_STRENGTH);
            vec2 roffset = (vogelDiskSample(i+14, 18, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter)) + poffset) * oneTexel * (5.0*REFRACT_STRENGTH);
            vec3 temp = vec3(0.0, texture2D(colortex3, info.coord + gboffset).gb);
            temp.r = texture2D(colortex3, info.coord + roffset).r;
            behind += temp;
        }
        behind /= 4.0;

    #else

        vec2 poffset = vec2(7.0*REFRACT_STRENGTH) * (1.0-info.albedo.a);
        vec2 gboffset = poffset * oneTexel * (4.0*REFRACT_STRENGTH);
        vec2 roffset = poffset * oneTexel * (5.0*REFRACT_STRENGTH);
        behind = vec3(0.0, texture2D(colortex3, info.coord + gboffset).gb);
        behind.r = texture2D(colortex3, info.coord + roffset).r;

    #endif

    #else
        vec3 behind = texture2D(colortex3, info.coord).rgb;
    #endif

    vec3 color = info.matMask != 5 ? 
        mix(behind, behind*info.albedo.rgb, clamp01(pow(info.albedo.a, 0.2))) 
        : mix(behind, behind+(info.albedo.rgb*2), clamp01(pow(info.albedo.a, 0.2))) ;

    #else
    vec3 behind = texture2D(colortex3, info.coord).rgb;
    vec3 color = calculateShading(info, viewPos, undistortedShadowPos, true);
    color = mix(behind, color, info.albedo.a);
    #endif

    return color;
}

// this is pretty much just the translucent shading function, but with some special kitty magic to make it prettier for weather! :3
vec3 calculateWeatherParticles(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos) {

    #ifdef TRANS_MULT

    #ifdef FAKE_REFRACT
    vec3 behind = vec3(0.0);
    vec2 oneTexel = 1.0 / vec2(viewWidth, viewHeight);

    #ifdef BLUR_REFRACT

        for (int i = 0; i < 4; i++) {
            vec2 poffset = vec2(7.0*REFRACT_STRENGTH) * (1.0-info.albedo.a);
            vec2 gboffset = (vogelDiskSample(i, 4, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter)) + poffset) * oneTexel * (4.0*REFRACT_STRENGTH);
            vec2 roffset = (vogelDiskSample(i+14, 18, interleavedGradientNoise(gl_FragCoord.xy+frameTimeCounter)) + poffset) * oneTexel * (5.0*REFRACT_STRENGTH);
            vec3 temp = vec3(0.0, texture2D(colortex3, info.coord + gboffset).gb);
            temp.r = texture2D(colortex3, info.coord + roffset).r;
            behind += temp;
        }
        behind /= 4.0;

    #else

        vec2 poffset = vec2(7.0*REFRACT_STRENGTH) * (1.0-info.albedo.a);
        vec2 gboffset = poffset * oneTexel * (4.0*REFRACT_STRENGTH);
        vec2 roffset = poffset * oneTexel * (5.0*REFRACT_STRENGTH);
        behind = vec3(0.0, texture2D(colortex3, info.coord + gboffset).gb);
        behind.r = texture2D(colortex3, info.coord + roffset).r;

    #endif

    #else
        vec3 behind = texture2D(colortex3, info.coord).rgb;
    #endif

    vec3 color = mix(behind, behind*info.albedo.rgb*5.0, clamp01(pow(info.albedo.a, 0.2)));
        

    #else
    vec3 behind = texture2D(colortex3, info.coord).rgb;
    vec3 color = calculateShading(info, viewPos, undistortedShadowPos, true);
    color = mix(behind, color, info.albedo.a);
    #endif

    return color;
}