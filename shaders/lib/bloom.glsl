const float PI = 3.1415926535897;
vec3 calcBloomTile(vec2 offset, float lod) {
    // get size of single texel
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    // get texture coordinate based on LOD
    vec2 coord = (texcoord.st - offset) * exp2(lod);
    vec2 scale = texelSize * exp2(lod);

    // discard bloom tile if out of bounds (prevents weird stretchy thingies from appearing)
    if (any(greaterThanEqual(abs(coord - 0.5), scale + 0.5))) {
        return vec3(0);
    }

    vec3 totalBloom = vec3(0.0);

    float totalWeight = 0.0;

    // calculate blurred tile
    for (int x=-2; x<=2; x++) { 
        for (int y=-2; y<=2; y++) {
            float weight = (PI-(x*x)-(y*y))/sqrt(4*PI)+5;
            totalBloom += texture2DLod(colortex4, coord + vec2(x,y) * scale, lod).rgb * weight;

            totalWeight += weight;
        }
    }

    return totalBloom / totalWeight;
}

vec3 getBloomTile(vec2 offset, float lod, vec2 coord){
	vec3 bloom = texture2D(colortex4, coord / pow(2.0, lod) + offset).rgb;
	return bloom;
}