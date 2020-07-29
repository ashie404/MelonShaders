vec3 calculateVL(in vec3 viewPos, in vec3 color) {

    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 endPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPos, 1.0);

    vec4 increment = normalize(endPos - startPos) * distance(endPos, startPos) / 8.0 * fract(frameTimeCounter * 4.0 + bayer64(gl_FragCoord.xy));
    vec4 currentPos = startPos;

    float visibility = 0.0;
    for (int i = 0; i < 8; i++) {
        currentPos += increment;

        vec3 currentPosShadow = distortShadow(currentPos.xyz) * 0.5 + 0.5;

        visibility += texture2D(shadowtex1, currentPosShadow.xy).r < currentPosShadow.z ? 0.0 : 1.0;
    }

    visibility /= 8.0;

    return visibility * color;
}