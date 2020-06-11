/* 
    Melon Shaders by J0SH
    https://j0sh.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:0 */
layout (location = 0) out vec4 albedoOut; // albedo output

in vec4 glcolor;

vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

void main() {
    albedoOut = vec4(toLinear(glcolor.rgb), glcolor.a);
}

#endif

// VERTEX SHADER //

#ifdef VERT

// outputs to fragment
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;
}

#endif