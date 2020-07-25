/*
    Melon Shaders
    By June (juniebyte)
    https://juniebyte.cf
*/

struct FragInfo {
    vec4 albedo;
    vec3 specular;
    vec3 normal;
    int matMask;
    vec2 lightmap;
    vec2 coord;
};

FragInfo getFragInfo(vec2 coord) {
    FragInfo f;

    vec4 tex1 = texture2D(colortex1, coord);
    vec2 matMaskAlpha = decodeLightmaps(tex1.y);

    f.albedo = vec4(texture2D(colortex0, coord).rgb, matMaskAlpha.y);
    f.specular = vec3(tex1.w, decodeLightmaps(tex1.z));
    f.normal = texture2D(colortex4, coord).xyz * 2.0 - 1.0;
    f.matMask = int((matMaskAlpha.x*10.0)+0.5);
    f.lightmap = decodeLightmaps(tex1.x);
    f.coord = coord;

    return f;
}