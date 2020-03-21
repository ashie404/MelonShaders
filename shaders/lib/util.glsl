#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)
#define transMAD(mat, v) (     mat3(mat) * (v) + (mat)[3].xyz)

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

vec3 toWorld(vec3 pos){
	return mat3(gbufferModelViewInverse) * pos + gbufferModelViewInverse[3].xyz;
}

vec3 toShadow(vec3 pos){
	vec3 shadowpos = mat3(shadowModelView) * pos + shadowModelView[3].xyz;
	shadowpos = projMAD(shadowProjection, shadowpos);
	return shadowpos;
}