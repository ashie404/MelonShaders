#version 120

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D texture;
uniform sampler2D depthtex1;
uniform sampler2D gaux2;

uniform vec3 sunPosition;

uniform int worldTime;
varying float isNight;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;
varying vec4 lmcoord;

varying vec4 position;
varying float isWater;
varying float isIce;
varying float isTransparent;

uniform int isEyeInWater;

uniform float viewWidth;
uniform float viewHeight;

#include "/lib/settings.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/util.glsl"
#include "/lib/dither.glsl"
#include "/lib/reflection.glsl"
#include "/lib/sky.glsl"


void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    if (isWater == 1)
    {
        // calculate reflections
        // calculate screen space reflections
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 viewPos = toNDC(screenPos);

        vec3 sunPosWorld = mat3(gbufferModelViewInverse) * sunPosition;
        vec3 normalWorld = mat3(gbufferModelViewInverse) * normal;
        vec3 sunReflection = reflect(normalize(position.xyz), normalize(normalWorld));
        float closenessOfSunToWater = dot(normalize(sunReflection), normalize(sunPosWorld));

        #ifdef SCREENSPACE_REFLECTIONS
        float z = texture2D(depthtex0, texcoord.st).r;
        float dither = bayer64(gl_FragCoord.xy);
        
        vec4 reflection = reflection(normalize(viewPos),normal,dither);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
        // calculate sky reflection
        vec3 reflectionPos = reflect(normalize(viewPos.xyz), normal);
        vec3 reflectionPosWS = mat3(gbufferModelViewInverse) * reflectionPos;
        vec3 skyReflection = GetSkyColor(normalize(reflectionPosWS), normalize(sunPosWorld), isNight);
        skyReflection /= 1.45;
        // calculate ssr color

        // snells window stuff
        vec3 n1 = isEyeInWater > 0 ? vec3(1.333) : vec3(1.00029);
        vec3 n2 = isEyeInWater > 0 ? vec3(1.00029) : vec3(1.333);
        vec3 rayDir = refract(normalize(viewPos), normal, n1.r/n2.r); // calculate snell's window
        if (isEyeInWater == 1) {
            if (rayDir == vec3(0))
            {
                // calculate reflections
                if (reflection.a > 0) {
                    // mix sky reflection and ssr
                    gl_FragData[0] = vec4(mix(vec3(0.03, 0.04, 0.07), reflection.rgb, 0.7), 1);
                }
                else {
                    if (closenessOfSunToWater < 0.998) {
                        // sky reflection
                        gl_FragData[0] = vec4(vec3(0.03, 0.04, 0.07), 1);
                    } else {
                        // sun reflection
                        gl_FragData[0] = vec4(0.95,0.95,0.9,0.9);
                    }
                }
            }  
            else {
                // use sky as water color, but make it more transparent
                gl_FragData[0] = vec4(skyReflection, 0.5);
            }
        }
        else {
            // calculate reflections
                if (reflection.a > 0) {
                    // mix sky reflection and ssr
                    gl_FragData[0] = vec4(mix(skyReflection, reflection.rgb, 0.7), 0.85);
                }
                else {
                    if (closenessOfSunToWater < 0.998) {
                        // sky reflection
                        gl_FragData[0] = vec4(skyReflection, 0.85);
                    } else {
                        // sun reflection
                        gl_FragData[0] = vec4(0.95,0.95,0.9,0.9);
                    }
                }
        }

        // if ssr is non-applicable
        #else

        // calculate basic color
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
        #endif
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else if (isIce == 1) {
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
        vec3 viewPos = toNDC(screenPos);

        // calculate ice reflectins
        #ifdef SCREENSPACE_REFLECTIONS
        #ifdef ICE_REFLECTIONS
        float z = texture2D(depthtex0, texcoord.st).r;
        float dither = bayer64(gl_FragCoord.xy);
        vec4 reflection = reflection(normalize(viewPos),normal,dither);
        reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
        blockColor = vec4(mix(blockColor.rgb, reflection.rgb, 0.35), 1);
        #endif
        #endif

        gl_FragData[0] = blockColor;
        // return 0.1 on depth alpha so composite knows to calculate lighting
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.1);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else if (isTransparent == 1) {
        gl_FragData[0] = blockColor;
        // return 0.1 on depth alpha so composite knows to calculate lighting
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0.1);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    else {
        gl_FragData[0] = blockColor;
        gl_FragData[1] = vec4(lmcoord.st / 16,0,0);
        gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0);
    }
    
}