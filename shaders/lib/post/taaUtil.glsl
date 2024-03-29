/*
    Melon Shaders
    By Ash (ashie404)
    https://ashiecorner.xyz
*/

// neighborhood clamping utils
vec3 RGBToYCoCg( vec3 RGB )
{
	float Y = dot(RGB, vec3(  1, 2,  1 )) * 0.25;
	float Co= dot(RGB, vec3(  2, 0, -2 )) * 0.25 + ( 0.5 * 256.0/255.0 );
	float Cg= dot(RGB, vec3( -1, 2, -1 )) * 0.25 + ( 0.5 * 256.0/255.0 );
	return vec3(Y, Co, Cg);
}

vec3 YCoCgToRGB( vec3 YCoCg )
{
	float Y= YCoCg.x;
	float Co= YCoCg.y - ( 0.5 * 256.0 / 255.0 );
	float Cg= YCoCg.z - ( 0.5 * 256.0 / 255.0 );
	float R= Y + Co-Cg;
	float G= Y + Cg;
	float B= Y - Co-Cg;
	return vec3(R,G,B);
}
const vec2 offsets[8] = vec2[8]( vec2(-1.0,-1.0), vec2(-1.0, 1.0), 
	vec2(1.0, -1.0),vec2(1.0,  1.0), 
	vec2(1.0, 0.0), vec2(0.0, -1.0), 
	vec2(0.0, 1.0),vec2(-1.0,  0.0));

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