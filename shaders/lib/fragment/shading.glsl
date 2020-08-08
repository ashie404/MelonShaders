/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

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

float getBlockerDepth(in vec2 coord, in vec3 undistortedShadowPos) {
    mat2 rotationMatrix = getRotationMatrix(coord);

    float blockerDepth = 0.0;
    int blockers = 0;

    for (int i = 0; i <= 4; i++) {
        vec2 offset = (vogelDiskSample(i, 4, interleavedGradientNoise(gl_FragCoord.xy))*4.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
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

    for (int i = 0; i <= 8; i++) {
        
        #ifdef PCSS
        vec2 offset = (vogelDiskSample(i, 8, interleavedGradientNoise(gl_FragCoord.xy))*softness*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #else
        vec2 offset = (vogelDiskSample(i, 8, interleavedGradientNoise(gl_FragCoord.xy))*SHADOW_SOFTNESS*0.5*(shadowMapResolution/2048.0)) / shadowMapResolution;
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
    return vec4((shadowCol / 64.0), visibility);
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
    float diffuseStrength = OrenNayar(normalize(viewPos), normalize(shadowLightPosition), info.normal, 1.0);
    vec3 diffuseLight = vec3(diffuseStrength);

    vec4 shadowLight = vec4(0.0);

    if (diffuseStrength > 0.0) shadowLight = getShadows(info.coord, viewPos, undistortedShadowPos);

    return min(diffuseLight, shadowLight.rgb);
}

vec3 calculateShading(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos) {
    // sky light & blocklight
    vec3 blockLight = (vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B) * 2.0 * BLOCKLIGHT_I) * pow(info.lightmap.x, 4.0);

    #if WORLD == -1

    vec3 color = (fogColor*0.25*texture2D(colortex5, info.coord).rgb)+blockLight;

    #elif WORLD == 1

    vec3 color = (fogColor*0.25*texture2D(colortex5, info.coord).rgb)+blockLight;

    #elif WORLD == 0

    vec3 skyLight = ambientColor * (texture2D(colortex5, info.coord).rgb * info.lightmap.y);

    vec3 shadowsDiffuse = getShadowsDiffuse(info, viewPos, undistortedShadowPos);

    // combine lighting
    vec3 color = (shadowsDiffuse*lightColor)+skyLight+blockLight;

    // subsurface scattering
    #ifdef SSS
    if (info.matMask == 1) {
        float depth = length(normalize(viewPos));
        float visibility = 0.0;

        mat2 rotationMatrix = getRotationMatrix(info.coord);

        float shadowBias = getShadowBias(viewPos, sunAngle);

        for (int i = 0; i <= 8; i++) {
            vec2 offset = (vogelDiskSample(i, 8, 0.5)*(12.0*SSS_SCATTER)*(shadowMapResolution/2048.0)) / shadowMapResolution;
            offset = rotationMatrix * offset;

            // sample shadow map
            vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
            float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r; // sampling shadow map

            visibility += step(shadowPos.z - shadowMapSample, shadowBias);
        }
        color += lightColor*clamp01((visibility/2.0)-depth)/2.0;
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
    vec3 behind = texture2D(colortex3, info.coord).rgb;

    #ifdef TRANS_COMPAT
    vec3 color = calculateShading(info, viewPos, undistortedShadowPos);
    color = mix(behind, color, info.albedo.a);
    #else
    vec3 color = behind*mix(vec3(1.0), info.albedo.rgb, clamp01(info.albedo.a*2.0));
    #endif

    return color;
}