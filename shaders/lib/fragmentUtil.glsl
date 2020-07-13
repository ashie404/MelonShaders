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
    vec4 tex3 = texture2D(colortex3, coord);

    f.albedo = tex0;
    f.lightmap = tex1.xy;
    f.matMask = int(tex1.a+0.5);
    f.normal = tex2.xyz * 2.0 - 1.0;
    f.specular = tex3;
    f.coord = coord;
    return f;
}