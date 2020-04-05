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

// reflection code based on BSL shaders by capt tatsu

vec4 reflection(vec3 viewPos, vec3 normal, float dither, in sampler2D sourcetex){
    vec4 color = vec4(0.0);
    vec4 pos = raytrace(depthtex0, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	float border = clamp(1.0 - pow(cdist(pos.st), 50.0), 0.0, 1.0);
	if(pos.z < 1.0 - 1e-5){
		color.a = texture2D(sourcetex, pos.st).a;
		if(color.a > 0.001) color.rgb = texture2D(sourcetex, pos.st).rgb;
		
		color.a *= border;
	}
    return color;
}
vec4 roughReflection(vec3 viewPos, vec3 normal, float dither, in sampler2D sourcetex, float smoothness){
    vec4 color = vec4(0.0);

    vec4 pos = raytrace(depthtex0, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	float border = clamp(1.0 - pow(cdist(pos.st), 50.0 * sqrt(smoothness)), 0.0, 1.0);
	
	if(pos.z < 1.0 - 1e-5){

		float dist = 1.0 - exp(-0.125 * (1.0 - smoothness) * pos.a);
		float lod = log2(viewHeight / 8.0 * (1.0 - smoothness) * dist);

		if(lod < 1.0){
			color.a = texture2DLod(sourcetex, pos.st, 1.0).b;
			if(color.a > 0.001) color.rgb = texture2DLod(colortex0, pos.st, 1.0).rgb;
		}else{
			for(int i = -2; i <= 2; i++){
				for(int j = -2; j <= 2; j++){
					vec2 refOffset = vec2(i, j) * pow(2.0, lod - 1.0) / vec2(viewWidth, viewHeight);
					vec2 refCoord = pos.st + refOffset;
					float alpha = texture2DLod(sourcetex, refCoord, lod).b;
					if(alpha > 0.001){
						color.rgb += texture2DLod(colortex0, refCoord, max(lod - 1.0, 0.0)).rgb;
						color.a += alpha;
					}
				}
			}
			color /= 25.0;
		}
		
		color *= color.a;
		color.a *= border;
	}
	
    return color;
}