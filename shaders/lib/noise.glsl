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