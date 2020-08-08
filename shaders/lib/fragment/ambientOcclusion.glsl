/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

float linearizeDepth(float depth) {
	return -1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

vec3 calcRTAO(vec3 viewPos, vec3 normal) {
    vec3 rtaoCol = vec3(0.0);
    float noisePattern = bayer64(gl_FragCoord.xy);

    for (int r = 1; r <= RTAO_RAYS; r++) {
        vec3 rayDir = sphereMap(fract(frameTimeCounter * 4.0 + hash32(uvec2(gl_FragCoord.xy*r)).xy));
        rayDir = mix(rayDir, normalize(upPosition), 0.3) * 5.0;
        if (dot(rayDir, normal) < 0.0) rayDir = -rayDir;

        vec3 rayInc = rayDir / RTAO_STEPS;

        vec3 currentRayPos = viewPos + rayInc * fract(frameTimeCounter * 4.0 + noisePattern);

        vec4 rayPosScreen = vec4(currentRayPos, 1.0);
        rayPosScreen = gbufferProjection * rayPosScreen;
        rayPosScreen /= rayPosScreen.w;
        rayPosScreen = rayPosScreen * 0.5 + 0.5;

        float depth = linearizeDepth(texture2D(depthtex1, rayPosScreen.xy).r);

        bool intersected = false;

        for (int i = 0; i < RTAO_STEPS; i++) {
            float diff = depth - currentRayPos.z;
            if (diff > 0.0 && diff < 4.5) {
                intersected = true; 
                break;
            }

            currentRayPos += rayInc;
            rayPosScreen = vec4(currentRayPos, 1.0);
            rayPosScreen = gbufferProjection * rayPosScreen;
            rayPosScreen /= rayPosScreen.w;
            rayPosScreen = rayPosScreen * 0.5 + 0.5;
            depth = linearizeDepth(texture2D(depthtex1, rayPosScreen.xy).r);
        }

        if (intersected) continue;

        rtaoCol += dot(normalize(rayDir), normal)*2.0;
    }
    rtaoCol /= RTAO_RAYS;
    return rtaoCol;
}