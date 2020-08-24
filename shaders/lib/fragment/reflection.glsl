/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

// Raytracing code from BSL Shaders ( https://bitslablab.com/ )

vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos){
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord){
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*1.85;
}

vec4 raytrace(sampler2D depthtex, vec3 viewPos, vec3 rayDir, float dither,
			  float maxf, float stp, float ref, float inc){
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos;

    vec3 vector = stp * rayDir;
    viewPos += vector;
	vec3 tvector = vector;

    int sr = 0;

    for(int i = 0; i < 30; i++){
        pos = nvec3(gbufferProjection * nvec4(viewPos)) * 0.5 + 0.5;
		if(pos.x < -0.05 || pos.x > 1.05 || pos.y < -0.05 || pos.y > 1.05) break;

		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex,pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
		dist = length(start - rfragpos);

        float err = length(viewPos - rfragpos);
		if(err < pow(length(vector) * pow(length(tvector), 0.11), 1.1) * 1.25){
                sr++;
                if(sr >= maxf) break;
				tvector -= vector;
                vector *= ref;
		}
        vector *= inc;
        tvector += vector;
		viewPos = start + tvector * (dither * 0.05 + 0.975);
    }

	return vec4(pos, dist);
}

// microfacet distribution (slightly modified, from Raspberry Shaders https://rutherin.netlify.app)

vec3 microfacetDistribution(in vec3 normal, vec3 noise, in float roughness) {
	noise = normalize(cross(normal, noise.xyz * 2.0 - 1.0));
	return normalize(noise.xyz * roughness + normal);
}

// reflections

vec4 reflection(vec3 viewPos, vec3 normal, float dither, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, 1.0, 0.1, 1.5);
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = texture2DLod(reflectionTex, rtPos.xy, 0.0); // sample 0.0 lod to prevent weird bright lines on certain GPUs
	}
	return clamp(outColor, 0.0, 1000.0);
}

vec4 roughReflection(vec3 viewPos, vec3 normal, float dither, float roughness, sampler2D reflectionTex, float stp, float inc) {
	roughness *= 1.5;

	vec4 outColor = vec4(0.0);

	#ifdef MICROFACET_REFL

	#if ROUGH_REFL_SAMPLES > 1
	for (int r = 1; r <= ROUGH_REFL_SAMPLES; r++) {
		normal = microfacetDistribution(normal, 
			fract(frameTimeCounter * 4.0 + texelFetch(noisetex, ivec2(gl_FragCoord.xy*r) & noiseTextureResolution - 1, 0).rgb), 
		roughness);
	#else
		normal = microfacetDistribution(normal, 
			fract(frameTimeCounter * 4.0 + texelFetch(noisetex, ivec2(gl_FragCoord.xy) & noiseTextureResolution - 1, 0).rgb), 
		roughness);
	#endif

		vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, stp, 0.1, inc);

		if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
			outColor += texture2DLod(reflectionTex, rtPos.xy, 0.0); // sample 0.0 lod to prevent weird bright lines on certain GPUs
		}
	#if ROUGH_REFL_SAMPLES > 1
	}
	#endif

	outColor /= ROUGH_REFL_SAMPLES;

	#else

	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, stp, 0.1, inc);
	float lod = clamp(roughness*24.0, 0.0, 4.0);
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = texture2DLod(reflectionTex, rtPos.xy, clamp(lod+clamp(rtPos.w*roughness*96.0, 0.0, roughness*96.0), 0.0, 7.0));
	}

	#endif
	
	return clamp(outColor, 0.0, 1000.0);
}