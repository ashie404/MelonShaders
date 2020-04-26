struct Fragment {
    vec4 albedo;
    vec4 specular;
    vec4 normal;
    int matMask;
    vec2 lightmap;
    vec2 coord;
};

Fragment getFragment(in vec2 coord) {
    Fragment f;
    f.albedo = texture2D(colortex0, coord);
    f.lightmap = texture2D(colortex1, coord).xy;
    f.matMask = int(texture2D(colortex1, coord).a+0.5);
    f.normal = texture2D(colortex2, coord);
    f.specular = texture2D(colortex3, coord);
    f.coord = coord;
    return f;
}