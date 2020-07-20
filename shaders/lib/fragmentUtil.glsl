/*
    Melon Shaders by June
    https://juniebyte.cf
*/

struct Fragment {
    vec4 albedo;
    vec4 specular;
    vec3 normal;
    int matMask;
    vec2 lightmap;
    vec2 coord;
};

Fragment getFragment(in vec2 coord) {
    Fragment f;
    
    vec4 tex1 = texture2D(colortex1, coord);

    f.albedo = texture2D(colortex0, coord);
    f.lightmap = clamp01(decodeLightmaps(tex1.x));
    f.matMask = int((clamp01(decodeLightmaps(tex1.z).x)*10.0)+0.5);
    f.normal = clamp(decodeNormals(tex1.y), -1.0, 1.0);
    f.specular = vec4(decodeVec3(tex1.w), 1.0);
    f.coord = coord;
    return f;
}