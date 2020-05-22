/*
    Melon Shaders by J0SH
    https://j0sh.cf
*/

// implementation based from wikipedia https://en.wikipedia.org/wiki/Halton_sequence
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

vec2 jitter() {
    vec2 scale = 1.25 / vec2(viewWidth, viewHeight);
    float time = frameCounter % 16;
    return vec2(haltonSeq(time, 2.0), haltonSeq(time, 4.0)) * scale + (-0.5 * scale);
}

vec2 reprojectCoords(vec3 coord) {
    vec4 pos = vec4(coord, 1.0)*2.0-1.0;

    pos = gbufferProjectionInverse*pos;
    pos /= pos.w;
    pos = gbufferModelViewInverse*pos;

    pos += vec4(cameraPosition-previousCameraPosition, 0.0);
    pos = gbufferPreviousModelView*pos;
    pos = gbufferPreviousProjection*pos;

    return (pos.xy/pos.w)*0.5+0.5;
}