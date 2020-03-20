// raytraced SSR code based on BSL shaders

const int maxf = 4;				//number of refinements
const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.25;			//refinement multiplier
const float inc = 2.0;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 normal, float dither) {
    vec4 color = vec4(0.0);
	#if AA == 2
	dither = fract(dither + frameTimeCounter);
	#endif

    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
	float border = 0.0;
	vec3 pos = vec3(0.0);
    for(int i=0;i<30;i++){
        pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if (pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1) break;
		float depth = texture2D(depthtex0,pos.xy).r;
		vec3 spos = vec3(pos.st, depth);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(length(fragpos.xyz-spos.xyz));
		if (err < pow(length(vector)*pow(length(tvector),0.11),1.1)*1.1){

                sr++;
                if (sr >= maxf){
                    break;
                }
				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector * (dither * 0.125 + 0.9375);
		fragpos = start + tvector;
    }
	
	if (pos.z <1.0-1e-5){
		border = clamp(1.0 - pow(cdist(pos.st), 200.0), 0.0, 1.0);
		color.a = float(texture2D(depthtex0,pos.xy).r < 1.0);
		if (color.a > 0.5) color.rgb = texture2D(colortex0, pos.st).rgb;
		color.rgb = clamp(color.rgb,vec3(0.0),vec3(8.0));
		color.a *= border;
	}
	
    return color;
}

vec4 raytraceRough(vec3 fragpos, vec3 normal, float dither, float r, vec2 noisecoord){
	r *= r;

	vec4 color = vec4(0.0);
	int steps = 1 + int(4 * r + (dither * 0.05));

	for(int i = 0; i < steps; i++){
		vec3 noise = vec3(texture2D(noisetex,noisecoord+0.1*i).xy*2.0-1.0,0.0);
		noise.xy *= 0.7*r*(i+1.0)/steps;
		noise.z = 1.0 - (noise.x * noise.x + noise.y * noise.y);

		vec3 tangent = normalize(cross(gbufferModelView[1].xyz, normal));
		mat3 tbnMatrix = mat3(tangent, cross(normal, tangent), normal);

		vec3 rnormal = normalize(tbnMatrix * noise);

		color += raytrace(fragpos,rnormal,dither);
	}
	color /= steps;
	
	return color;
}