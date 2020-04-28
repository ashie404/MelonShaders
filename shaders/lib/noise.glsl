/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

// various noise functions ripped from different sources

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float hash(float n)
{
  return fract(sin(n) * 43758.5453123);
}

float noise(vec3 x)
{
  vec3 f = fract(x);
  float n = dot(floor(x), vec3(1.0, 157.0, 113.0));
  return mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                 mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
             mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                 mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

#define OCTAVES 6

const mat3 m = mat3(0.0, 1.60,  1.20, -1.6, 0.72, -0.96, -1.2, -0.96, 1.28);

float fbm(vec3 p)
{
  float f = 0.0;
  f += noise(p) / 2; p = m * p * 1.1;
  f += noise(p) / 4; p = m * p * 1.2;
  f += noise(p) / 6; p = m * p * 1.3;
  f += noise(p) / 12; p = m * p * 1.4;
  f += noise(p) / 24;
  return f;
}

float fbm2(vec3 p)
{
  float f = 0.0;
  f += noise(p) / 2; p = m * p * 1.1;
  f += noise(p) / 4; p = m * p * 1.2;
  f -= noise(p) / 12; p = m * p * 1.4;
  f -= noise(p) / 6; p = m * p * 1.3;
  f -= noise(p) / 16; p = m * p * 1.4;
  f -= noise(p) / 24;
  f += noise(p) / 11; p = m * p * 1.1;
  f += noise(p) / 13; p = m * p * 1.5;
  f += noise(p) / 24;
  f -= noise(p) / 2; p = m * p * 1.7;
  f += noise(p) / 16; p = m * p * 1.7;
  f += noise(p) / 24; p = m * p * 0.6;
  return f;
}

float hash12(vec2 p)
{
	uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
	uint n = (q.x ^ q.y) * 1597334673U;
	return float(n) * (1.0 / float(0xffffffffU));
}

vec2 hash22(vec2 p)
{
	uvec2 q = uvec2(ivec2(p))*uvec2(1597334673U, 3812015801U);
	q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
	return vec2(q) * (1.0 / float(0xffffffffU));
}

float perlinNoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec2 curlNoise(vec2 uv)
{
    vec2 eps = vec2(0., 1.);
    
    float n1, n2, a, b;
    n1 = perlinNoise(uv + eps);
    n2 = perlinNoise(uv - eps);
    a = (n1 - n2) / (2. * eps.y);
    
    n1 = perlinNoise(uv + eps.yx);
    n2 = perlinNoise(uv - eps.yx);
    b = (n1 - n2)/(2. * eps.y);
    
    return vec2(a, -b);
}

float worleyNoise(vec2 uv, float freq, float t, bool curl)
{
    uv *= freq;
    uv += t + (curl ? curlNoise(uv*2.) : vec2(0.)); // exaggerate the curl noise a bit
    
    vec2 id = floor(uv);
    vec2 gv = fract(uv);
    
    float minDist = 100.;
    for (float y = -1.; y <= 1.; ++y)
    {
        for(float x = -1.; x <= 1.; ++x)
        {
            vec2 offset = vec2(x, y);
            vec2 h = hash22(id + offset) * .8 + .1; // .1 - .9
    		h += offset;
            vec2 d = gv - h;
           	minDist = min(minDist, dot(d, d));
        }
    }
    
    return minDist;
}

float perlinFbm (vec2 uv, float freq, float t)
{
    uv *= freq;
    uv += t;
    float amp = .5;
    float noise = 0.;
    for (int i = 0; i < 8; ++i)
    {
        noise += amp * perlinNoise(uv);
        uv *= 2.;
        amp *= .5;
    }
    return noise;
}

vec4 worleyFbm(vec2 uv, float freq, float t, bool curl)
{
    // worley0 isn't used for high freq noise, so we can save a few ops here
    float worley0 = 0.;
    if (freq < 4.)
    	worley0 = 1. - worleyNoise(uv, freq * 1., t * 1., false);
    float worley1 = 1. - worleyNoise(uv, freq * 2., t * 2., curl);
    float worley2 = 1. - worleyNoise(uv, freq * 4., t * 4., curl);
    float worley3 = 1. - worleyNoise(uv, freq * 8., t * 8., curl);
    float worley4 = 1. - worleyNoise(uv, freq * 16., t * 16., curl);
    
    // Only generate fbm0 for low freq
    float fbm0 = (freq > 4. ? 0. : worley0 * .625 + worley1 * .25 + worley2 * .125);
    float fbm1 = worley1 * .625 + worley2 * .25 + worley3 * .125;
    float fbm2 = worley2 * .625 + worley3 * .25 + worley4 * .125;
    float fbm3 = worley3 * .75 + worley4 * .25;
    return vec4(fbm0, fbm1, fbm2, fbm3);
}