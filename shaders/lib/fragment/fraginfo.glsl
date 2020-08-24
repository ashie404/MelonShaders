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
    vec2 matMaskAlpha = clamp01(decodeLightmaps(tex1.y));

    f.albedo = vec4(texture2D(colortex0, coord).rgb, matMaskAlpha.y);
    f.specular = clamp01(vec3(tex1.w, tex1.z, 0.0));
    f.normal = mat3(gbufferModelView) * (texture2D(colortex4, coord).xyz * 2.0 - 1.0);
    f.matMask = int((matMaskAlpha.x*10.0)+0.5);
    f.lightmap = clamp01(decodeLightmaps(tex1.x));
    f.coord = coord;

    return f;
}