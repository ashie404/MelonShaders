float haltonSeq(float index, float base) {
    float o = 0.0;
    float f = 1.0;

    while (index > 0) {
        f = f/base;
        o = o + f * (int(index)%int(base));
        index = index/base;
    }

    return o;
}

vec2 jitter(float w) {
    vec2 scale = w / vec2(viewWidth, viewHeight) * 0.25;
    float time = frameCounter % 16;
    return vec2(haltonSeq(time, 2.0), haltonSeq(time, 4.0)) * scale + (-0.5 * scale);
}