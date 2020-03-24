#include "/lib/raytrace.glsl"

uniform sampler2D depthtex1;

// reflection code based on BSL shaders by capt tatsu

vec4 reflection(vec3 viewPos, vec3 normal, float dither, sampler2D sourceTex){
    vec4 color = vec4(0.0);

    vec4 pos = Raytrace(depthtex1, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	float border = clamp(1.0 - pow(cdist(pos.st), 50.0), 0.0, 1.0);
	
	if(pos.z < 1.0 - 1e-5){
		color.a = texture2D(sourceTex, pos.st).a;
		if(color.a > 0.001) color.rgb = texture2D(sourceTex, pos.st).rgb;
		
		color.a *= border;
	}
    
    return color;
}