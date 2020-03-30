#version 450 compatibility

// outputs to fragment shader

out vec3 tintColor;
out vec3 normal;
out vec4 texcoord;
out vec4 lmcoord;
out vec4 position;
out float isWater;

// uniforms

uniform float frameTimeCounter;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float viewWidth;
uniform float viewHeight;
attribute vec4 mc_Entity;

// defines

#define DRAG_MULT 0.048
#define ITERATIONS_NORMAL 48
#define WATER_DEPTH 1.25

// includes

#include "/lib/settings.glsl"

// returns vec2 with wave height in X and its derivative in Y
vec2 wavedx(vec2 position, vec2 direction, float speed, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float getwaves(vec2 position, int iterations){
	float iter = 0.0;
    float phase = 6.0;
    float speed = 0.5;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i=0;i<iterations;i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, speed, phase, frameTimeCounter*6);
        position += normalize(p) * res.y * weight * DRAG_MULT;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
        speed *= 1.07;
    }
    return w / ws;
}

void main()
{
    #ifndef ORTHOGRAPHIC
    gl_Position = ftransform();
    #else
    gl_Position = gl_ModelViewMatrix * gl_Vertex * vec4(1 * (viewHeight / viewWidth), 1, -0.01, 8);
    #endif
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    normal = normalize(gl_NormalMatrix * gl_Normal);

    if (mc_Entity.x == 8) {
        isWater = 1;
        vec3 worldPos = position.xyz + cameraPosition;
        float waves = getwaves(worldPos.xz, 48);
        normal.y -= waves;
        position.y -= waves/2;
        gl_Position.y -= waves/2;
    } else {
        isWater = 0;
    }
}