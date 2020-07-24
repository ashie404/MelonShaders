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

    f.albedo = vec4(texture2D(colortex0, coord).rgb, tex1.z);
    f.specular = decodeSpecular(tex1.w);
    f.normal = texture2D(colortex4, coord).xyz;
    f.matMask = int((tex1.y*10.0)+0.5);
    f.lightmap = decodeLightmaps(tex1.x);
    f.coord = coord;

    return f;
}