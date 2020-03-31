vec3 calculateBloomTile(const float lod, vec2 offset) {
    vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
    vec2 coord = (texcoord.st - offset) * exp2(lod);
    vec2 scale = pixel * exp2(lod);
    
    if (any(greaterThanEqual(abs(coord - 0.5), scale + 0.5)))
        return vec3(0.0);
    
    vec3  bloom       = vec3(0.0);
    float totalWeight = 0.0;
    
    for (int y = -3; y <= 3; y++) {
        for (int x = -3; x <= 3; x++) {
            float weight  = clamp01(1.0 - length(vec2(x, y)) / 4.0);
                  weight *= weight;
            
            bloom += texture2DLod(colortex4, coord + vec2(x, y) * scale, lod).rgb * weight;
            totalWeight += weight;
        }
    }
    return bloom / totalWeight;
}

vec3 calculateBloomTiles() {
    vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 bloom = vec3(0.0);
    bloom += calculateBloomTile(2.0, vec2(0.0                     ,                    0.0));
    bloom += calculateBloomTile(3.0, vec2(0.0                     , 0.25   + pixel.y * 2.0));
    bloom += calculateBloomTile(4.0, vec2(0.125    + pixel.x * 2.0, 0.25   + pixel.y * 2.0));
    bloom += calculateBloomTile(5.0, vec2(0.1875   + pixel.x * 4.0, 0.25   + pixel.y * 2.0));
    bloom += calculateBloomTile(6.0, vec2(0.125    + pixel.x * 2.0, 0.3125 + pixel.y * 4.0));
    bloom += calculateBloomTile(7.0, vec2(0.140625 + pixel.x * 4.0, 0.3125 + pixel.y * 4.0));

    return bloom * 1.3;
}

vec3 getBloomTile(float lod, vec2 coord, vec2 offset){
	vec3 bloom = texture2D(colortex4, coord / pow(2.0, lod) + offset).rgb;
	return bloom;
}