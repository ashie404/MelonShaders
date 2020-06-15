/*
    Melon Shaders by June
    https://j0sh.cf
*/

// SSAO from BSL Shaders ( https://bitslablab.com/ )

vec2 OffsetDist(float x, int s){
	float n = fract(x * 1.414) * 3.1415;
    return vec2(cos(n), sin(n)) * x / s;
}

float AmbientOcclusion(sampler2D depth, float dither){
	float ao = 0.0;

	int samples = 5;
	dither = fract(frameTimeCounter * 4.0 + dither);
	
	float d = texture2D(depth, texcoord).r;
	float hand = float(d < 0.56);
	d = linear(d);
	
	float sd = 0.0, angle = 0.0, dist = 0.0;
	float fovScale = gbufferProjection[1][1] / 2.74747742;
	float distScale = max((far - near) * d + near, 6.0);
	vec2 scale = 0.6 * vec2(1.0, aspectRatio) * fovScale / distScale;

	for(int i = 1; i <= samples; i++) {
		vec2 offset = OffsetDist(i + dither, samples) * scale;

		sd = linear(texture2D(depth, texcoord + offset).r);
        float ssaoSample = (far - near) * (d - sd) * 2.0;
		if (hand > 0.5) ssaoSample *= 1024.0;
		angle = clamp(0.5 - ssaoSample, 0.0, 1.0);
		dist = clamp(0.25 * ssaoSample - 1.0, 0.0, 1.0);

		sd = linear(texture2D(depth, texcoord - offset).r);
		ssaoSample = (far - near) * (d - sd) * 2.0;
		if (hand > 0.5) ssaoSample *= 1024.0;
		angle += clamp(0.5 - ssaoSample, 0.0, 1.0);
		dist += clamp(0.25 * ssaoSample - 1.0, 0.0, 1.0);
		
		ao += clamp(angle + dist, 0.0, 1.0);
	}
	ao /= samples;
	
	return pow(ao, 1.5);
}