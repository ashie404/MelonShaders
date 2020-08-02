vec3 calculateVL(in vec3 viewPos, in vec3 color) {

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 endPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);

    vec4 increment = normalize(endPos - startPos) * distance(endPos, startPos) / 8.0 * fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy));
    vec4 currentPos = startPos;

    float visibility = 0.0;
    for (int i = 0; i < 4; i++) {
        currentPos += increment;

        vec3 currentPosShadow = distortShadow(currentPos.xyz) * 0.5 + 0.5;

        visibility += texture2D(shadowtex1, currentPosShadow.xy).r < currentPosShadow.z ? 0.0 : 1.0;
    }

    visibility /= 4.0;

    return visibility * color;
}

void calculateFog(inout vec3 color, in vec3 viewPos, in float depth0) {
    #ifdef FOG 

    #if WORLD == 0
    if (isEyeInWater == 0) {
        vec3 fogCol = texture2DLod(colortex2, texcoord*0.1, 6.0).rgb*2.0;
        if (depth0 != 1.0) {
            vec3 fogCol2 = fogCol;
            if (eyeBrightnessSmooth.y <= 64 && eyeBrightnessSmooth.y > 8) {
                fogCol2 = mix(vec3(0.1), fogCol2, clamp01((eyeBrightnessSmooth.y-9)/55.0));
            } else if (eyeBrightnessSmooth.y <= 8) {
                fogCol2 = vec3(0.1);
            }
            color = mix(color, fogCol2, clamp01(length(viewPos)/196.0*FOG_DENSITY));
        }
        #ifdef VL
        color += calculateVL(viewPos, lightColor*fogCol/8.0*mix(1.0, 0.15, clamp01(times.y))*VL_DENSITY);
        #endif
    }
    #elif WORLD == -1
    if (isEyeInWater == 0 && depth0 != 1.0) {
        color = mix(color, fogColor, clamp01(length(viewPos)/84.0*FOG_DENSITY));
    }
    #elif WORLD == 1
    if (isEyeInWater == 0 && depth0 != 1.0) {
        color = mix(color, fogColor, clamp01(length(viewPos)/84.0*FOG_DENSITY));
    }
    #endif

    #endif

    // draw water fog
    if (isEyeInWater == 1) {
        vec3 transmittance = exp(-waterCoeff * length(viewPos.xyz));
        color *= transmittance;
        #ifdef VL
        color += calculateVL(viewPos.xyz, vec3(0.1, 0.5, 0.9)/12.0*mix(1.0, 0.15, clamp01(times.w))*VL_DENSITY);
        #endif
    }
}