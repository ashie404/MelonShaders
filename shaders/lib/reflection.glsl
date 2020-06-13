/*
    Melon Shaders by June
    https://j0sh.cf
*/

vec4 reflection(vec3 viewPos, vec3 normal, float dither, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	vec4 rtPos = raytrace(depthtex1, viewPos, normal, dither, 4.0, 1.0, 0.1, 2.0);
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = texture2D(reflectionTex, rtPos.xy);
	}
	return outColor;
}

vec4 roughReflection(vec3 viewPos, vec3 normal, float dither, float roughness, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	vec4 rtPos = raytrace(depthtex1, viewPos, normal, dither, 4.0, 1.0, 0.1, 2.0);
	float lod = roughness*12.0;
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0 && rtPos.z < 1.0 - 1e-5) {
		outColor = texture2DLod(reflectionTex, rtPos.xy, lod);
	}
	return outColor;
}