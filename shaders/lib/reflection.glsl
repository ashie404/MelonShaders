// raytrace and reflection code based on BSL shaders

uniform sampler2D depthtex1;

uniform sampler2D gaux2;

vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos){
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord){
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*1.85;
}

vec4 Raytrace(sampler2D depthtex, vec3 viewPos, vec3 normal, float dither,
			  float maxf, float stp, float ref, float inc){
	vec3 pos = vec3(0.0);
	float dist = 0.0;

	vec3 start = viewPos;

    vec3 vector = stp * reflect(normalize(viewPos), normalize(normal));
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

vec4 SimpleReflection(vec3 viewPos, vec3 normal, float dither){
    vec4 color = vec4(0.0);

    vec4 pos = Raytrace(depthtex1, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	float border = clamp(1.0 - pow(cdist(pos.st), 50.0), 0.0, 1.0);
	
	if(pos.z < 1.0 - 1e-5){
		color.a = texture2D(gaux2, pos.st).a;
		if(color.a > 0.001) color.rgb = texture2D(gaux2, pos.st).rgb;
		
		color.a *= border;
	}
	
    return color;
}