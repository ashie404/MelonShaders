vec3 calculateColoredVL(in vec3 viewPos, in vec3 color, in bool lowQ) {

    int steps = lowQ ? 2 : VL_STEPS;

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 endPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);

    vec4 increment = normalize(endPos - startPos) * distance(endPos, startPos) / steps * fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy));
    vec4 currentPos = startPos;

    float visibility = 0.0;
    vec3 vlColor = vec3(0.0);
    for (int i = 0; i < steps; i++) {
        currentPos += increment;
        vec3 currentPosShadow = distortShadow(currentPos.xyz) * 0.5 + 0.5;

        float shadow0 = texture2D(shadowtex0, currentPosShadow.xy).r;
        float shadow1 = texture2D(shadowtex1, currentPosShadow.xy).r;

        if (!(shadow1 < currentPosShadow.z)) {
            visibility += 1.0;
            if (shadow0 < currentPosShadow.z) vlColor += texture2D(shadowcolor0, currentPosShadow.xy).rgb*2.0;
            else vlColor += vec3(1.0);
        }
    }

    visibility /= steps;
    vlColor /= steps;

    return (visibility*VL_DENSITY) * (color*vlColor);
}

vec3 calculateVL(in vec3 viewPos, in vec3 color, in bool lowQ) {

    int steps = lowQ ? 2 : VL_STEPS;

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 endPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);

    vec4 increment = normalize(endPos - startPos) * distance(endPos, startPos) / steps * fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy));
    vec4 currentPos = startPos;

    float visibility = 0.0;

    for (int i = 0; i < steps; i++) {
        currentPos += increment;
        vec3 currentPosShadow = distortShadow(currentPos.xyz) * 0.5 + 0.5;

        visibility += texture2D(shadowtex1, currentPosShadow.xy).r < currentPosShadow.z ? 0.0 : 1.0;
    }

    visibility /= steps;

    return (visibility*VL_DENSITY) * color;
}


void calculateFog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in float depth0, in float depth1, in bool lowQVL) {
    #ifdef FOG 

    #if WORLD == 0
    if (isEyeInWater < 0.5) {
        #ifndef SKYTEX
        vec3 fogCol = texture2DLod(colortex2, texcoord*0.1, 6.0).rgb*2.0;
        #else
        vec3 fogCol = texture2DLod(colortex2, texcoord, 7.0).rgb*2.0;
        #endif
        
        vec3 fogCol2 = fogCol;
        if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
            fogCol2 = mix(vec3(0.05), fogCol2, clamp01((eyeBrightnessSmooth.y-9)/55.0));
        } else if (eyeBrightnessSmooth.y <= 8) {
            fogCol2 = vec3(0.05);
        }
        color = depth0 != 1.0 ? mix(color, fogCol2, clamp01(length(viewPos)/128.0*FOG_DENSITY)) 
            : mix(color, fogCol2, 1.0 - clamp01(worldPos.y/640.0));

        #ifdef VL
        float mie = clamp01(miePhase(dot(normalize(viewPos.xyz), normalize(shadowLightPosition)), depth0, 0.025));
        color += calculateColoredVL(viewPos, mix(fogCol, lightColor, mie)/8.0*mix(1.0, 0.25, clamp01(times.y)), lowQVL);
        #endif
    }
    #elif WORLD == -1
    if (isEyeInWater < 0.5 && depth0 != 1.0) {
        color = mix(color, fogColor, clamp01(length(viewPos)/84.0*FOG_DENSITY));
    }
    #elif WORLD == 1
    if (isEyeInWater < 0.5 && depth0 != 1.0) {
        color = mix(color, fogColor, clamp01(length(viewPos)/84.0*FOG_DENSITY));
    }
    #endif

    #endif

    // draw water fog
    #ifdef FOG
    else if (isEyeInWater > 0.5 && isEyeInWater < 1.5) {
    #else
    if (isEyeInWater > 0.5 && isEyeInWater < 1.5) {
    #endif
        vec3 transmittance = exp(-waterCoeff * length(viewPos.xyz));
        color *= transmittance;
        #ifdef VL
        float mie = clamp01(pow(miePhase(dot(normalize(viewPos.xyz), normalize(shadowLightPosition)), depth0, 0.025), 0.5));
        vec3 scattering = calculateVL(viewPos.xyz, mix(vec3(0.0), lightColor*4.0, mie), lowQVL);
        scattering *= waterScatterCoeff; // scattering coefficent
        scattering *= (vec3(1.0) - transmittance) / waterCoeff;
        color += scattering;
        #endif
    } else if (isEyeInWater > 1.5 && isEyeInWater < 2.5) { // lava fog
        color = mix(color, vec3(1.0, 0.05, 0.01), clamp01(length(viewPos.xyz)/24.0));
    } else if (isEyeInWater > 2.5) { // powder snow fog
        color = mix(color, vec3(0.1, 0.3, 1.0)*2.0, clamp01(length(viewPos.xyz)/24.0));
    }
}