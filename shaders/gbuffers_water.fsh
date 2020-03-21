#version 120

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

#include "/lib/framebuffer.glsl"
#include "/lib/sky.glsl"

uniform sampler2D texture;

uniform vec3 sunPosition;

uniform float worldTime;
uniform float viewWidth;
uniform float viewHeight;
varying float isNight;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

varying vec4 position;
varying float isWater;
varying float isIce;
varying float isTransparent;

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    if (isWater == 1)
    {
        // calculate sun reflection
        vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	    vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        vec3 sunPosWorld = mat3(gbufferModelViewInverse) * sunPosition;
        vec3 normalWorld = mat3(gbufferModelViewInverse) * normal;
        vec3 reflection = reflect(normalize(position.xyz), normalize(normalWorld));
        float closenessOfSunToWater = dot(normalize(reflection), normalize(sunPosWorld));

        if (closenessOfSunToWater < 0.998) {
            // basic sky reflection
            vec3 reflectionPos = reflect(normalize(viewPos.xyz), normal);
            vec3 reflectionPosWS = mat3(gbufferModelViewInverse) * reflectionPos;
            vec3 skyReflection = GetSkyColor(normalize(reflectionPosWS), normalize(sunPosWorld), isNight);
            gl_FragData[0] = vec4(skyReflection, 0.85);
        }
        else {
            // sun reflection
            gl_FragData[0] = vec4(0.95,0.95,0.9,0.9);
        }
        // return 0.5 on depth alpha so composite knows to calculate water reflections
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.5);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else if (isIce == 1) {
        gl_FragData[0] = blockColor;
        // return 0.4 on depth alpha so composite knows to calculate ice reflections 
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.4);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else if (isTransparent == 1) {
        gl_FragData[0] = blockColor;
        // return 0.3 on depth alpha so composite knows to calculate lighting
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.3);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else {
        gl_FragData[0] = blockColor;
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    
}