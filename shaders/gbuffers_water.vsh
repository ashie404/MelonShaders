#version 120

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

attribute vec4 mc_Entity;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;

varying float isWater;
varying float isIce;
varying float isTransparent;

uniform int worldTime;

#define DRAG_MULT 0.048
#define ITERATIONS_NORMAL 48
#define WATER_DEPTH 1.25


float getIsTransparent(in float materialId) {
    if (materialId == 160.0) { // stained glass pane
        return 1.0;
    }
    if (materialId == 95.0) { //stained glass
        return 1.0;
    }
    if (materialId == 79.0) { //ice
        return 1.0;
    }
    if (materialId == 8.0 || materialId == 9.0) { //water 
        return 1.0;
    }
    return 0.0;
}

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
        vec2 res = wavedx(position, p, speed, phase, worldTime/1.75);
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
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    lmcoord = gl_MultiTexCoord1;
    tintColor = gl_Color.rgb;
    position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
    normal = normalize(gl_NormalMatrix * gl_Normal);

    if (mc_Entity.x == 8 || mc_Entity.x == 9) {
        isIce = 0;
        isWater = 1;
        //normal = mat3(gbufferModelViewInverse) * normal;
        normal.y -= getwaves(ftransform().xz, 48);
        //gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
    }
    else if (mc_Entity.x == 79.0) {
        isIce = 1;
        isWater = 0;
    }
    else {
        isIce = 0;
        isWater = 0;
    }
    isTransparent = getIsTransparent(mc_Entity.x);
}