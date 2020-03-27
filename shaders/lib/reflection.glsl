#include "/lib/raytrace.glsl"

uniform sampler2D depthtex1;

#define Scale vec3(.8, .8, .8)
#define Thing 19.19

vec3 hash(vec3 a)
{
    a = fract(a * Scale);
    a += dot(a, a.yxz + Thing);
    return fract((a.xxy + a.yxx)*a.zyx);
}

vec4 Reflection(in vec3 viewPos, in vec3 normal, in float dither, in sampler2D sourceTex, in float roughness) {
	vec4 color = vec4(0);



	// trace ray to find reflected position
	vec4 ray = raytrace(depthtex1, normalize(viewPos), toWorld(normal), dither, 4, 1.0, 0.1, 2.0);

	// jitter based on roughness
	//vec3 jitt = mix(vec3(0), hash(vec3(roughness)+viewPos), roughness);

	//ray.xy += jitt.zy;

	// if the position is good for reflecting (data is on screen)
	if (ray.z < 1.0 - 1e-5) {
		color.a = texture2D(sourceTex, ray.st).a;
		if (color.a > 0.0001) {
			color.rgb = texture2DLod(sourceTex, ray.st, roughness).rgb;
		}
	}

	return color;
}

// reflection code based on BSL shaders by capt tatsu

vec4 reflection(vec3 viewPos, vec3 normal, float dither, in sampler2D sourcetex){
    vec4 color = vec4(0.0);
    vec4 pos = raytrace(depthtex1, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	float border = clamp(1.0 - pow(cdist(pos.st), 50.0), 0.0, 1.0);
	if(pos.z < 1.0 - 1e-5){
		color.a = texture2D(sourcetex, pos.st).a;
		if(color.a > 0.001) color.rgb = texture2D(sourcetex, pos.st).rgb;
		
		color.a *= border;
	}
    return color;
}