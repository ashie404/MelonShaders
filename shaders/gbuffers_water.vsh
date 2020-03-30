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
#include "/lib/noise.glsl"

float waves(vec2 pos, int iterations, int detail) {
    // this is just totally random code to create fancy waves
    float iter = 0.0;
    float finalWave = 0.0;
    float time = frameTimeCounter*WAVE_SPEED;
    vec2 position = pos/detail;
    for (int i=0; i<=iterations; i++) {
        float wx = -abs(sin(position.x-i+time*4));
        float wy = -abs(cos(position.y+i-time*4));
        float wz = abs(cos(sin(wx+wy/position.x-i+time*16)));
        float wfbm = abs(sin(fbm(vec3(wx,wy,wz)+position.xyx)));
        finalWave += wx*wy+wz/wfbm;
    }

    return finalWave/(iterations/detail);
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
        #ifdef WATER_WAVES
        vec3 worldPos = position.xyz + cameraPosition;
        float waves = waves(worldPos.xz, 48, WAVE_SCALE)/(10*WAVE_SCALE);
        normal.y -= waves;
        position.y -= waves;
        gl_Position.y -= waves;
        #endif
    } else {
        isWater = 0;
    }
}