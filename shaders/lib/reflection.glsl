/*
    Melon Shaders by June
    https://juniebyte.cf
*/

vec4 reflection(vec3 viewPos, vec3 normal, float dither, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	float fresnel = clamp01(fresnel(0.2, 0.1, 1.0, viewPos, normal)+0.2);
	#ifdef HQ_REFLECTIONS
	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, 1.0, 0.1, 1.0);
	#else
	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, 1.0, 0.1, 2.0);
	#endif
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = max(texture2D(reflectionTex, reprojectCoords(rtPos.xyz).xy), 0.0);
	}
	return vec4(outColor.rgb, clamp01(outColor.a-clamp01(1.0-fresnel)));
}

vec4 roughReflection(vec3 viewPos, vec3 normal, float dither, float roughness, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	#ifdef HQ_REFLECTIONS
	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, 1.0, 0.1, 1.0);
	#else
	vec4 rtPos = raytrace(depthtex0, viewPos, reflect(normalize(viewPos), normalize(normal)), dither, 4.0, 1.0, 0.1, 2.0);
	#endif
	float lod = roughness*12.0;
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = max(texture2DLod(reflectionTex, reprojectCoords(rtPos.xyz).xy, lod), 0.0);
	}
	return outColor;
}