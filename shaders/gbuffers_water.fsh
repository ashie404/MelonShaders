#version 120

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

#include "lib/framebuffer.glsl"
#include "lib/sky.glsl"
#include "lib/raytrace.glsl"
#include "lib/dither.glsl"

uniform sampler2D texture;

uniform vec3 sunPosition;

uniform float worldTime;
uniform float viewWidth;
uniform float viewHeight;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

varying vec4 position;
varying float isWater;

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

        float dither = bayer64(gl_FragCoord.xy);

        if (closenessOfSunToWater < 0.998) {
            // basic sky reflection
            vec3 reflectionPos = reflect(normalize(viewPos.xyz), normal);
            vec3 reflectionPosWS = mat3(gbufferModelViewInverse) * reflectionPos;
            vec3 skyReflection = GetSkyColor(normalize(reflectionPosWS), normalize(sunPosWorld));

            // screen space reflection!
            vec4 reflection = raytrace(normalize(viewPos.xyz), normal, dither);
            reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
            if(reflection.a < 1.0) {
                vec3 reflectionPos = reflect(normalize(viewPos.xyz), normal);
                vec3 reflectionPosWS = mat3(gbufferModelViewInverse) * reflectionPos;
                skyReflection = GetSkyColor(normalize(reflectionPosWS), normalize(sunPosWorld));
            }

            reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));

            GCOLOR_OUT = reflection;
        }
        else {
            // sun reflection
            GCOLOR_OUT = vec4(0.95,0.95,0.9,0.85);
        }
        GDEPTH_OUT = vec4(lmcoord.st / 16,0,0);
        GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else {
        GCOLOR_OUT = blockColor;
        GDEPTH_OUT = vec4(lmcoord.st / 16,0,0);
        GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
    }
    
}