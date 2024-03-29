/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

float cubeLength(vec2 v) {
	return pow(abs(v.x * v.x * v.x) + abs(v.y * v.y * v.y), 1.0 / 3.0);
}

float getShadowDistortFactor(vec2 v) {
	return cubeLength(v) + 0.075;
}

vec3 distortShadow(vec3 v, float factor) {
	return vec3(v.xy / factor, v.z * 0.5);
}

vec3 distortShadow(vec3 v) {
	return distortShadow(v, getShadowDistortFactor(v.xy));
}