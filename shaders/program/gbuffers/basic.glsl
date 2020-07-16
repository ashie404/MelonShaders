/* 
    Melon Shaders by June
    https://juniebyte.cf
*/

#include "/lib/settings.glsl"
#include "/lib/util.glsl"

// FRAGMENT SHADER //

#ifdef FRAG

/* DRAWBUFFERS:01 */
layout (location = 0) out vec4 albedoOut; // albedo output
layout (location = 1) out vec4 lmNormalMatOut; // lightmap, normal map, and material mask output

in vec4 glcolor;
in vec3 normal;

vec3 toLinear(vec3 srgb) {
    return mix(
        srgb * 0.07739938080495356, // 1.0 / 12.92 = ~0.07739938080495356
        pow(0.947867 * srgb + 0.0521327, vec3(2.4)),
        step(0.04045, srgb)
    );
}

void main() {
    albedoOut = vec4(toLinear(glcolor.rgb), glcolor.a);
    lmNormalMatOut = vec4(
        encodeLightmaps(vec2(0.0, 1.0)), 
        encodeNormals(clamp(normal, -1.0, 1.0)), 
        0.0, 
        encodeVec3(vec3(0.0))
    );
}

#endif

// VERTEX SHADER //

#ifdef VERT

// outputs to fragment
out vec4 glcolor;
out vec3 normal;

void main() {
	gl_Position = ftransform();
	glcolor = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}

#endif