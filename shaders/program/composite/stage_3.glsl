/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:06 */
layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec4 taaOut;

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex6;

uniform sampler2D depthtex0;

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

#include "/lib/temporalUtil.glsl"

void main() {
    #ifdef TAA
    vec2 reprojectedCoord = reprojectCoords(vec3(texcoord, texture2D(depthtex0, texcoord).r));
    vec3 current = RGBToYCoCg(texture2D(colortex0, texcoord).rgb);
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

    colorOut = texture2D(colortex6, texcoord);
    
    taaOut = vec4((texture2D(colortex0, texcoord+jitter()).rgb/2.0)+(YCoCgToRGB(history)/2.0), 1.0);
    #else
    colorOut = texture2D(colortex0, texcoord);
    #endif
}

#endif

// VERTEX SHADER //

#ifdef VERT

out vec2 texcoord;

uniform float sunAngle;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif