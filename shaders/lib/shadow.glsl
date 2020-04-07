uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor1;

#include "/lib/BSDF.glsl"

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

vec3 screenViewToCam(vec3 screenViewVector){
  return mat3(gbufferModelViewInverse)*screenViewVector;
}

vec3 shadowViewToCam(vec3 shadowViewVector){
  return mat3(shadowModelViewInverse)*shadowViewVector;
}

vec3 screenToCamPos(vec3 screenPos){
  vec4 tmp = gbufferProjectionInverse*vec4(screenPos*2.-1.,1.);
  return (gbufferModelViewInverse*tmp/tmp.w).xyz;
}

vec3 shadowToCamPos(vec3 shadowPos){
  vec4 tmp = shadowProjectionInverse*vec4(shadowPos*2.-1.,1.);
  return (shadowModelViewInverse*tmp/tmp.w).xyz;
}
vec3 camToShadowPos(vec3 camPos){
  vec4 tmp = shadowModelView*vec4(camPos,1.);
  return (shadowProjection*tmp/tmp.w).xyz;
}

#define GA 2.39996322973
const mat2 Grot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));

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

vec3 getGI(in vec3 shadowPos, in vec3 undistortedShadowPos, in vec3 viewVec, in vec3 screenPos, in Fragment frag, in float sunVis) {
    vec3 rsmColor = vec3(0.0);
    float totalSamples = 0.0;

    const float pi2 = 6.28318530718 ;

    float dither = bayer16(frag.coord);
    vec2 offsetDirection = vec2(cos(dither*pi2),sin(dither*pi2));

    for (int x = -8; x<=8; x++) {
        for (int y = -8; y<=8; y++) {
            vec2 offset = (vec2(x*8, y*8)) / shadowMapResolution;
            /*float sampleDepth = texture2D(shadowtex0, shadowPos.xy+offset).r;

            vec3 sampleColor = texture2D(shadowcolor0, shadowPos.xy+offset).rgb;
            vec3 sampleNormal = texture2D(shadowcolor1, shadowPos.xy+offset).rgb*2.0-1.0;
            vec3 delta = (mat3(gbufferModelViewInverse) * screenPos)-(mat3(gbufferModelViewInverse) * shadowPos);
            vec3 deltaDir = normalize(delta);
            float diffuseBounce = 1;
            if (sunVis > 0.9) {
                diffuseBounce = max(0.0,dot(-deltaDir,mat3(gbufferModelViewInverse) * frag.normal));
            }
            rsmColor += sampleColor*max(dot(mat3(gbufferModelViewInverse) * lightVector, sampleNormal),0)*diffuseBounce;
            totalSamples += 1;*/
            vec2 rsmPosition = shadowPos.xy + offset;
            vec3 worldPos = mat3(gbufferModelViewInverse) * vec3(rsmPosition, texture2D(shadowtex0, rsmPosition).g);
            vec3 sampleColor = texture2D(shadowcolor0, rsmPosition).rgb;
            vec3 sampleNormal = texture2D(shadowcolor1, shadowPos.xy+offset).rgb*2.0-1.0;
            vec3 lightDir = normalize(worldPos - shadowPos);
            float dist = (1.0 / (distance(worldPos, shadowPos) * 0.5));
            if (length(sampleColor) < 1.0 && sunVis > 0.4) {
              rsmColor += sampleColor * dist;    // max(vec3(0.0), color * max(0.0, dot(lightDir, worldNormal)) * dist);
            }
            totalSamples += 1;
        }
    }

    return rsmColor / totalSamples; 
}

vec3 calculateLighting(in Fragment frag, in Lightmap lightmap, in vec4 shadowPos, in vec3 undistortedShadow, in vec3 screenPos, in vec3 viewVec, in PBRData pbrData) {
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

    // 0.3 emission is tag for hardcoded sss blocks
    if (frag.emission == 0.3) {
        float depth = length(viewVec);
        float strength = 1.0-(depth-(sunLight.a/16));
        vec3 subsurfColor = mix(vec3(0), lightColor/2, clamp01(strength))*SSS_STRENGTH;
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

     #ifdef GI
    // RSM GI

    color += texture2D(colortex6, frag.coord).rgb;
    #endif

    // multiply by albedo to get final color
    color *= frag.albedo;

    return color;

}