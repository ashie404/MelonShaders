/*
    Melon Shaders by J0SH
    https://j0sh.cf
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
    return mat2(
        cos(rotationAmount), -sin(rotationAmount),
        sin(rotationAmount), cos(rotationAmount)
    );
}

// shadowmap sampling
vec4 getShadows(in vec2 coord, in vec3 shadowPos)
{
    vec3 shadowCol = vec3(0.0); // shadow color
    mat2 rotationMatrix = getRotationMatrix(coord); // rotation matrix for shadow
    float visibility = 0;
    for (int i = 0; i <= 24; i++) {
        vec2 offset = (poissonDisk[i]*2) / shadowMapResolution;
        offset = rotationMatrix * offset;
        // sample shadow map
        float shadowMapSample = texture2D(shadowtex0, shadowPos.xy + offset).r; // sampling shadow map
        visibility += step(shadowPos.z - shadowMapSample, SHADOW_BIAS);
        
        // check if shadow color should be sampled, if yes, sample and add colored shadow, if no, just add the shadow map sample
        if (texture2D(shadowtex0, shadowPos.xy + offset).r < texture2D(shadowtex1, shadowPos.xy + offset).r ) {
            vec3 colorSample = texture2D(shadowcolor0, shadowPos.xy + offset).rgb; // sample shadow color
            shadowCol += colorSample*8;
        } else {
            shadowCol += mix(vec3(shadowMapSample), vec3(1.0), visibility);
        }
    }
    return vec4(shadowCol / 192, visibility);
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
vec3 calculateShading(in Fragment fragment, in PBRData pbrData, in vec3 viewVec, in vec3 shadowPos) {
    // calculate skylight
    vec3 skyLight = ambientColor * fragment.lightmap.y;

    // calculate blocklight
    vec3 blockLightColor = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)*0.75;
    vec3 blockLight = blockLightColor * fragment.lightmap.x;

    // calculate diffuse lighting
    float diffuseStrength = OrenNayar(normalize(viewVec), normalize(shadowLightPosition), normalize(fragment.normal), pow(1.0 - pbrData.smoothness, 2.0));
    vec3 diffuseLight = diffuseStrength * lightColor;

    // calculate shadows
    vec4 shadowLight = getShadows(fragment.coord, shadowPos);

    // combine lighting
    vec3 color = (shadowLight.rgb*diffuseLight)+skyLight+blockLight;

    // 1 on matmask is hardcoded SSS
    #ifdef SSS
    if (fragment.matMask == 1) {
        float depth = length(viewVec);
        float strength = 1.0-(depth-(shadowLight.a/16));
        vec3 subsurfColor = mix(vec3(0), lightColor/4, clamp01(strength))*SSS_STRENGTH;
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

    // multiply by albedo to get final color
    color *= fragment.albedo.rgb;

    return color;
}

// basic shading (diffuse, specular, blocklight, skylight, no shadows or subsurface scattering) used for translucents
vec3 calculateBasicShading(in Fragment fragment, in PBRData pbrData, in vec3 viewVec) {
    // calculate skylight
    vec3 skyLight = ambientColor * fragment.lightmap.y;

    // calculate blocklight
    vec3 blockLightColor = vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)*0.35;
    vec3 blockLight = blockLightColor * fragment.lightmap.x;

    // calculate diffuse lighting
    float diffuseStrength = OrenNayar(normalize(viewVec), normalize(shadowLightPosition), normalize(fragment.normal), 0.7);
    vec3 diffuseLight = diffuseStrength * lightColor;

    // combine lighting
    vec3 color = diffuseLight+skyLight+blockLight;

    #ifdef SPECULAR
    // calculate specular highlights
    float specularStrength = ggx(normalize(fragment.normal), normalize(viewVec), normalize(shadowLightPosition), pbrData);
    vec3 specularHighlight = specularStrength * lightColor;
    color += specularHighlight;
    #endif

    // multiply by albedo to get final color
    color *= fragment.albedo.rgb;

    return color;
}