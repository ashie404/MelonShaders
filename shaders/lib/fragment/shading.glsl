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

    for (int i = 0; i <= 16; i++) {
        vec2 offset = (poissonDisk[i]*4.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
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
vec4 getShadows(in vec2 coord, in vec3 undistortedShadowPos)
{
    vec3 shadowCol = vec3(0.0); // shadow color
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    float visibility = 0;

    #ifdef PCSS
    float blockerDepth = clamp01(getBlockerDepth(coord, undistortedShadowPos));
    float softness = clamp(blockerDepth*80.0, 0.0, 4.0);
    #endif

    for (int i = 0; i <= 16; i++) {
        #ifdef PCSS
        vec2 offset = (poissonDisk[i]*softness*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #else
        vec2 offset = (poissonDisk[i]*SHADOW_SOFTNESS*0.5*(shadowMapResolution/2048.0)) / shadowMapResolution;
        #endif
        offset = rotationMatrix * offset;

        // sample shadow map
        vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
        float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r; // sampling shadow map

        visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
        
        // check if shadow color should be sampled, if yes, sample and add colored shadow, if no, just add the shadow map sample
        if (shadowMapSample < texture2D(shadowtex1, shadowPos.xy).r) {
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

vec3 calculateShading(in FragInfo info, in vec3 viewPos, in vec3 undistortedShadowPos) {
    float diffuseStrength = OrenNayar(normalize(viewPos), normalize(shadowLightPosition), info.normal, 1.0);
    vec3 diffuseLight = vec3(diffuseStrength);

    vec4 shadowLight = vec4(0.0);

    #ifdef SSS
    if (diffuseStrength > 0.0 || info.matMask == 1) shadowLight = getShadows(info.coord, undistortedShadowPos);
    #else
    if (diffuseStrength > 0.0) shadowLight = getShadows(info.coord, undistortedShadowPos);
    #endif

    // sky light & blocklight
    vec3 skyLight = ambientColor * info.lightmap.y;
    vec3 blockLight = vec3(0.9, 0.4, 0.1) * info.lightmap.x;

    // combine lighting
    vec3 color = (min(diffuseLight, shadowLight.rgb)*lightColor)+skyLight+blockLight;

    // subsurface scattering
    #ifdef SSS
    if (info.matMask == 1) {
        float depth = length(normalize(viewPos));
        float visibility = 0.0;

        mat2 rotationMatrix = getRotationMatrix(info.coord);

        for (int i = 0; i <= 8; i++) {
            vec2 offset = (poissonDisk[i]*12.0*(shadowMapResolution/2048.0)) / shadowMapResolution;
            offset = rotationMatrix * offset;

            // sample shadow map
            vec3 shadowPos = distortShadow(vec3(undistortedShadowPos.xy + offset, undistortedShadowPos.z)) * 0.5 + 0.5;
            float shadowMapSample = texture2D(shadowtex0, shadowPos.xy).r; // sampling shadow map

            visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
        }

        color += lightColor*clamp01(visibility-depth);
    }
    #endif

    // multiply by albedo to get final color
    color *= info.albedo.rgb;

    return color;
}