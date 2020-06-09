/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

vec4 reflection(vec3 viewPos, vec3 normal, float dither, sampler2D reflectionTex) {
	vec4 outColor = vec4(0.0);
	vec4 rtPos = raytrace(depthtex0, viewPos, normal, dither, 4.0, 1.0, 0.1, 2.0);
	if (rtPos.w <= 100.0 && rtPos.x >= 0.0 && rtPos.x <= 1.0 && rtPos.y >= 0.0 && rtPos.y <= 1.0) {
		outColor = texture2D(reflectionTex, rtPos.xy);
	}
	return outColor;
}