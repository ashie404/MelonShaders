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

// shading calculation
vec3 calculateShading(in vec3 color, in vec2 texcoord, in vec3 shadowPos) {

}