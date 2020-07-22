/*
    Melon Shaders by June
    https://juniebyte.cf
*/

vec3 calcVolumetricLighting(in vec3 viewPos, in vec3 color, in float densityMult, in bool noonDensityDecrease, in bool varyingDensity) {
    float noon = times.y;

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 stepSize = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);
    stepSize /= VL_STEPS;
    stepSize *= fract(frameTimeCounter * 8.0 + bayer64(gl_FragCoord.xy));

    startPos -= stepSize;

    vec4 currentPos = startPos;

    float visibility = 0.0;

    for (int i = 0; i < VL_STEPS; i++) {
        currentPos += stepSize;

        vec3 currentPosShadow = distort(currentPos.xyz) * 0.5 + 0.5;

        bool intersection = texture2D(shadowtex1, currentPosShadow.xy).r < currentPosShadow.z;
        visibility += intersection ? 0.0 : 1.0;
    }

    visibility /= VL_STEPS;
    
    #ifdef VARYING_VL_DENSITY
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    worldPos.xz += vec2(frameTimeCounter);
    float fogNoise = varyingDensity ? fbm((worldPos.xyz/8.0)) : 1.0;
    #else
    float fogNoise = 1.0;
    #endif

    vec3 vlColor = mix(vec3(0.0), color*((VL_DENSITY/15.0)*densityMult*fogNoise), clamp01(visibility));
    vlColor *= noonDensityDecrease ? mix(vec3(1.0), vec3(0.05), clamp01(noon)) : vec3(1.0);

    return vlColor;
}