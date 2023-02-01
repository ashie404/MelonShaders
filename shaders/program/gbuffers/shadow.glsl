/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FSH

/* RENDERTARGETS: 0 */
out vec4 shadowcolorOut;

// Inputs from vertex shader
in vec2 texcoord;
in vec4 glcolor;

// Uniforms
uniform sampler2D texture;

// Includes

void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;

	shadowcolorOut = color;
}


#endif

// VERTEX SHADER //

#ifdef VSH

// Outputs to fragment shader
out vec2 texcoord;
out vec4 glcolor;

// Uniforms
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjectionInverse;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

// Includes
#include "/lib/vertex/distortion.glsl"

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;

	gl_Position = ftransform();
    
    gl_Position.xyz = distortShadow(gl_Position.xyz);
}

#endif