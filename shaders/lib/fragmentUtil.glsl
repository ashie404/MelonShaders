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

    vec4 tex0 = texture2D(colortex0, coord);
    vec4 tex1 = texture2D(colortex1, coord);
    vec4 tex2 = texture2D(colortex2, coord);

    f.albedo = tex0;
    f.lightmap = decodeLightmaps(tex1.x);
    f.matMask = int(tex1.z+0.5);
    f.normal = decodeNormals(tex1.y);
    f.specular = tex2;
    f.coord = coord;
    return f;
}