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
        vec2 noise = texelFetch(noisetex, ivec2(gl_FragCoord.xy*r) & noiseTextureResolution - 1, 0).rg;
        noise = noise * (255.0/256.0);
        float t = float(frameCounter & 255);
        noise = fract(noise + (t * PHI));
        noise.x = (noise.x > 0.5 ? 1.0 - noise.x : noise.x) * 2.0;
        noise.y = (noise.y > 0.5 ? 1.0 - noise.y : noise.y) * 2.0;

        vec3 rayDir = sphereMap(noise);
        
        rayDir = mix(rayDir, normalize(upPosition), 0.3) * 5.0;
        if (dot(rayDir, normal) < 0.0) rayDir = -rayDir;

        vec3 rayInc = rayDir / RTAO_STEPS;

        vec3 currentRayPos = viewPos + rayInc * fract(frameTimeCounter * 4.0 + noisePattern);

        vec4 rayPosScreen = gbufferProjection * vec4(currentRayPos, 1.0);
        rayPosScreen /= rayPosScreen.w;
        rayPosScreen = rayPosScreen * 0.5 + 0.5;

        float depth = linearizeDepth(texture2D(depthtex1, rayPosScreen.xy).r);

        bool intersected = false;

        for (int i = 0; i < RTAO_STEPS; i++) {
            float diff = depth - currentRayPos.z;
            if (diff > 0.0 && diff < 4.0) {
                intersected = true; 
                break;
            }

            currentRayPos += rayInc;
            rayPosScreen = gbufferProjection * vec4(currentRayPos, 1.0);
            rayPosScreen /= rayPosScreen.w;
            rayPosScreen = rayPosScreen * 0.5 + 0.5;
            depth = linearizeDepth(texture2D(depthtex1, rayPosScreen.xy).r);
        }

        if (!intersected) rtaoCol += dot(normalize(rayDir), normal)*2.0;
    }
    rtaoCol /= RTAO_RAYS;
    return rtaoCol;
}