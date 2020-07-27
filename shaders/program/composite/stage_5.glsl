/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* DRAWBUFFERS:06 */
layout (location = 0) out vec3 colorOut;
layout (location = 1) out vec3 taaOut;

// Inputs from vertex shader
in vec2 texcoord;

// Uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex6;

uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

// Includes
#include "/lib/post/taaUtil.glsl"

void main() {
    #ifdef TAA
    float depth0 = texture2D(depthtex0, texcoord).r;

    vec2 reprojectedCoord = reprojectCoords(vec3(texcoord, depth0));
    vec3 current = vec3(0.0);

    current = RGBToYCoCg(texture2D(colortex0, texcoord).rgb);

    vec3 history = RGBToYCoCg(texture2D(colortex6, reprojectedCoord).rgb);

    vec3 colorAvg = current;
    vec3 colorVar = current*current;

    // neighborhood clamping to reject invalid temporal history (fixes ghosting)
    for(int i = 0; i < 8; i++)
    {
        vec3 ycocg = RGBToYCoCg(texture2D(colortex0, texcoord+(offsets[i]/vec2(viewWidth, viewHeight)), 0).xyz);
        colorAvg += ycocg;
        colorVar += ycocg*ycocg;
    }
    colorAvg /= 9.0;
    colorVar /= 9.0;
    float gColorBoxSigma = 0.75;
	vec3 sigma = sqrt(max(vec3(0.0), colorVar - colorAvg*colorAvg));
	vec3 colorMin = colorAvg - gColorBoxSigma * sigma;
	vec3 colorMax = colorAvg + gColorBoxSigma * sigma;
    
    history = clamp(history, colorMin, colorMax);

    history = YCoCgToRGB(history);

    current = YCoCgToRGB(current);

    colorOut = mix(current, history, 0.85);
    
    taaOut = mix(current, history, 0.95);
    #else
    colorOut = texture2D(colortex0, texcoord).rgb;
    #endif
}

#endif

// VERTEX SHADER //

#ifdef VSH

out vec2 texcoord;

uniform float sunAngle;

uniform float viewWidth;
uniform float viewHeight;

uniform int frameCounter;

#include "/lib/util/taaJitter.glsl"

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif