float noise11(float p) {
	return fract(sin(p*633.1847) * 9827.95);
}
    
float noise21(vec2 p) {
	return fract(sin(p.x*827.221 + p.y*3228.8275) * 878.121);
}

vec2 noise22(vec2 p) {
	return fract(vec2(sin(p.x*9378.35), sin(p.y*75.589)) * 556.89);
}