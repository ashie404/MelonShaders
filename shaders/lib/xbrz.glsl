// 4xBRZ upscaling code from shadertoy, adapted to support alpha channel and clamp edges of subtextures to support texture atlases
// https://www.shadertoy.com/view/tdfyD2

#define LUMINANCE_WEIGHT 1.0
#define EQUAL_COLOR_TOLERANCE 20.0/255.0
#define DOMINANT_DIRECTION_THRESHOLD 2.6
#define STEEP_DIRECTION_THRESHOLD 4.6

float DistYCbCr(const vec4 pixA, const vec4 pixB)
{
	const vec4 w = vec4(0.2627, 0.6780, 0.0593, 1);
	const float scaleB = 0.5 / (1.0 - w.b);
	const float scaleR = 0.5 / (1.0 - w.r);
	vec4 diff = pixA - pixB;
	float Y = dot(diff, w);
	float Cb = scaleB * (diff.b - Y);
	float Cr = scaleR * (diff.r - Y);
		
	return sqrt( ((LUMINANCE_WEIGHT * Y) * (LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr) );
}
	
bool IsPixEqual(const vec4 pixA, const vec4 pixB)
{
	return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}
float reduce(const vec4 color)
{
	return dot(color, vec4(65536.0, 256.0, 1.0, 1.0));
}	
bool IsBlendingNeeded(const int blend0,const int blend1,const int blend2,const int blend3)
{
	//return any(!(blend == int4(BLEND_NONE,BLEND_NONE,BLEND_NONE,BLEND_NONE)));
    return blend0 != 0||blend1 != 0||blend2 != 0||blend3 != 0;
}
	
	//---------------------------------------
	// Input Pixel Mapping:  --|21|22|23|--
	//                       19|06|07|08|09
	//                       18|05|00|01|10
	//                       17|04|03|02|11
	//                       --|15|14|13|--
	//
	// Output Pixel Mapping:  06|07|08|09
	//                        05|00|01|10
	//                        04|03|02|11
	//                        15|14|13|12


vec4 four_xBRZ(vec2 texture_size,vec2 texCoord,sampler2D tex,vec2 minCoord,vec2 maxCoord)
{

	vec2 f = fract(texCoord*texture_size);

	//---------------------------------------
	// Input Pixel Mapping:  20|21|22|23|24
	//                       19|06|07|08|09
	//                       18|05|00|01|10
	//                       17|04|03|02|11
	//                       16|15|14|13|12
    float dx = 1.0/texture_size.x;
    float dy = 1.0/texture_size.y;
    vec4 t1 = texCoord.xxxy + vec4( -dx, 0, dx,-2.0*dy); // A1 B1 C1
	vec4 t2 = texCoord.xxxy + vec4( -dx, 0, dx, -dy); // A B C
	vec4 t3 = texCoord.xxxy + vec4( -dx, 0, dx, 0); // D E F
	vec4 t4 = texCoord.xxxy + vec4( -dx, 0, dx, dy); // G H I
	vec4 t5 = texCoord.xxxy + vec4( -dx, 0, dx, 2.0*dy); // G5 H5 I5
	vec4 t6 = texCoord.xyyy + vec4(-2.0*dx,-dy, 0, dy); // A0 D0 G0
	vec4 t7 = texCoord.xyyy + vec4( 2.0*dx,-dy, 0, dy); // C4 F4 I4

	vec4 src[25];
  
	src[21] = texture2D(tex, clamp(floor(t1.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[22] = texture2D(tex, clamp(floor(t1.yw*texture_size)/texture_size, minCoord, maxCoord));
	src[23] = texture2D(tex, clamp(floor(t1.zw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 6] = texture2D(tex, clamp(floor(t2.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 7] = texture2D(tex, clamp(floor(t2.yw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 8] = texture2D(tex, clamp(floor(t2.zw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 5] = texture2D(tex, clamp(floor(t3.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 0] = texture2D(tex, clamp(floor(t3.yw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 1] = texture2D(tex, clamp(floor(t3.zw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 4] = texture2D(tex, clamp(floor(t4.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 3] = texture2D(tex, clamp(floor(t4.yw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 2] = texture2D(tex, clamp(floor(t4.zw*texture_size)/texture_size, minCoord, maxCoord));
	src[15] = texture2D(tex, clamp(floor(t5.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[14] = texture2D(tex, clamp(floor(t5.yw*texture_size)/texture_size, minCoord, maxCoord));
	src[13] = texture2D(tex, clamp(floor(t5.zw*texture_size)/texture_size, minCoord, maxCoord));
	src[19] = texture2D(tex, clamp(floor(t6.xy*texture_size)/texture_size, minCoord, maxCoord));
	src[18] = texture2D(tex, clamp(floor(t6.xz*texture_size)/texture_size, minCoord, maxCoord));
	src[17] = texture2D(tex, clamp(floor(t6.xw*texture_size)/texture_size, minCoord, maxCoord));
	src[ 9] = texture2D(tex, clamp(floor(t7.xy*texture_size)/texture_size, minCoord, maxCoord));
	src[10] = texture2D(tex, clamp(floor(t7.xz*texture_size)/texture_size, minCoord, maxCoord));
	src[11] = texture2D(tex, clamp(floor(t7.xw*texture_size)/texture_size, minCoord, maxCoord));

		float v[9];
		v[0] = reduce(src[0]);
		v[1] = reduce(src[1]);
		v[2] = reduce(src[2]);
		v[3] = reduce(src[3]);
		v[4] = reduce(src[4]);
		v[5] = reduce(src[5]);
		v[6] = reduce(src[6]);
		v[7] = reduce(src[7]);
		v[8] = reduce(src[8]);
		
		int blendResult0 = 0;
		int blendResult1 = 1;
		int blendResult2 = 2;
		int blendResult3 = 3;
		
		// Preprocess corners
		// Pixel Tap Mapping: --|--|--|--|--
		//                    --|--|07|08|--
		//                    --|05|00|01|10
		//                    --|04|03|02|11
		//                    --|--|14|13|--
		
		// Corner (1, 1)
		if ( !((v[0] == v[1] && v[3] == v[2]) || (v[0] == v[3] && v[1] == v[2])) )
		{
			float dist_03_01 = DistYCbCr(src[ 4], src[ 0]) + DistYCbCr(src[ 0], src[ 8]) + DistYCbCr(src[14], src[ 2]) + DistYCbCr(src[ 2], src[10]) + (4.0 * DistYCbCr(src[ 3], src[ 1]));
			float dist_00_02 = DistYCbCr(src[ 5], src[ 3]) + DistYCbCr(src[ 3], src[13]) + DistYCbCr(src[ 7], src[ 1]) + DistYCbCr(src[ 1], src[11]) + (4.0 * DistYCbCr(src[ 0], src[ 2]));
			bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_03_01) < dist_00_02;
			blendResult2 = ((dist_03_01 < dist_00_02) && (v[0] != v[1]) && (v[0] != v[3])) ? ((dominantGradient) ? 2 : 1) : 0;
		}
		
		
		// Pixel Tap Mapping: --|--|--|--|--
		//                    --|06|07|--|--
		//                    18|05|00|01|--
		//                    17|04|03|02|--
		//                    --|15|14|--|--
		// Corner (0, 1)
		if ( !((v[5] == v[0] && v[4] == v[3]) || (v[5] == v[4] && v[0] == v[3])) )
		{
			float dist_04_00 = DistYCbCr(src[17], src[ 5]) + DistYCbCr(src[ 5], src[ 7]) + DistYCbCr(src[15], src[ 3]) + DistYCbCr(src[ 3], src[ 1]) + (4.0 * DistYCbCr(src[ 4], src[ 0]));
			float dist_05_03 = DistYCbCr(src[18], src[ 4]) + DistYCbCr(src[ 4], src[14]) + DistYCbCr(src[ 6], src[ 0]) + DistYCbCr(src[ 0], src[ 2]) + (4.0 * DistYCbCr(src[ 5], src[ 3]));
			bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_03) < dist_04_00;
			blendResult3 = ((dist_04_00 > dist_05_03) && (v[0] != v[5]) && (v[0] != v[3])) ? ((dominantGradient) ? 2 : 1) : 0;
		}
		
		// Pixel Tap Mapping: --|--|22|23|--
		//                    --|06|07|08|09
		//                    --|05|00|01|10
		//                    --|--|03|02|--
		//                    --|--|--|--|--
		// Corner (1, 0)
		if ( !((v[7] == v[8] && v[0] == v[1]) || (v[7] == v[0] && v[8] == v[1])) )
		{
			float dist_00_08 = DistYCbCr(src[ 5], src[ 7]) + DistYCbCr(src[ 7], src[23]) + DistYCbCr(src[ 3], src[ 1]) + DistYCbCr(src[ 1], src[ 9]) + (4.0 * DistYCbCr(src[ 0], src[ 8]));
			float dist_07_01 = DistYCbCr(src[ 6], src[ 0]) + DistYCbCr(src[ 0], src[ 2]) + DistYCbCr(src[22], src[ 8]) + DistYCbCr(src[ 8], src[10]) + (4.0 * DistYCbCr(src[ 7], src[ 1]));
			bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_07_01) < dist_00_08;
			blendResult1 = ((dist_00_08 > dist_07_01) && (v[0] != v[7]) && (v[0] != v[1])) ? ((dominantGradient) ? 2 : 1) : 0;
		}
		
		// Pixel Tap Mapping: --|21|22|--|--
		//                    19|06|07|08|--
		//                    18|05|00|01|--
		//                    --|04|03|--|--
		//                    --|--|--|--|--
		// Corner (0, 0)
		if ( !((v[6] == v[7] && v[5] == v[0]) || (v[6] == v[5] && v[7] == v[0])) )
		{
			float dist_05_07 = DistYCbCr(src[18], src[ 6]) + DistYCbCr(src[ 6], src[22]) + DistYCbCr(src[ 4], src[ 0]) + DistYCbCr(src[ 0], src[ 8]) + (4.0 * DistYCbCr(src[ 5], src[ 7]));
			float dist_06_00 = DistYCbCr(src[19], src[ 5]) + DistYCbCr(src[ 5], src[ 3]) + DistYCbCr(src[21], src[ 7]) + DistYCbCr(src[ 7], src[ 1]) + (4.0 * DistYCbCr(src[ 6], src[ 0]));
			bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_07) < dist_06_00;
			blendResult0 = ((dist_05_07 < dist_06_00) && (v[0] != v[5]) && (v[0] != v[7])) ? ((dominantGradient) ? 2 : 1) : 0;
		}
		
		vec4 dst[16];
		dst[ 0] = src[0];
		dst[ 1] = src[0];
		dst[ 2] = src[0];
		dst[ 3] = src[0];
		dst[ 4] = src[0];
		dst[ 5] = src[0];
		dst[ 6] = src[0];
		dst[ 7] = src[0];
		dst[ 8] = src[0];
		dst[ 9] = src[0];
		dst[10] = src[0];
		dst[11] = src[0];
		dst[12] = src[0];
		dst[13] = src[0];
		dst[14] = src[0];
		dst[15] = src[0];
		
		// Scale pixel
		if (IsBlendingNeeded(blendResult0,blendResult1,blendResult2,blendResult3))
		{
			float dist_01_04 = DistYCbCr(src[1], src[4]);
			float dist_03_08 = DistYCbCr(src[3], src[8]);
			bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[4]) && (v[5] != v[4]);
			bool haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[8]) && (v[7] != v[8]);
			bool needBlend = (blendResult2 != 0);
			bool doLineBlend = (  blendResult2 >= 2 ||
							   !((blendResult1 != 0 && !IsPixEqual(src[0], src[4])) ||
								 (blendResult3 != 0 && !IsPixEqual(src[0], src[8])) ||
								 (IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && !IsPixEqual(src[0], src[2])) ) );
			
			vec4 blendPix = ( DistYCbCr(src[0], src[1]) <= DistYCbCr(src[0], src[3]) ) ? src[1] : src[3];
			dst[ 2] = mix(dst[ 2], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
			dst[ 9] = mix(dst[ 9], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
			dst[10] = mix(dst[10], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
			dst[11] = mix(dst[11], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[12] = mix(dst[12], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
			dst[13] = mix(dst[13], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[14] = mix(dst[14], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
			dst[15] = mix(dst[15], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);
			
			
			dist_01_04 = DistYCbCr(src[7], src[2]);
			dist_03_08 = DistYCbCr(src[1], src[6]);
			haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[2]) && (v[3] != v[2]);
			haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[6]) && (v[5] != v[6]);
			needBlend = (blendResult1 != 0);
			doLineBlend = (  blendResult1 >= 2 ||
						  !((blendResult0 != 0 && !IsPixEqual(src[0], src[2])) ||
							(blendResult2 != 0 && !IsPixEqual(src[0], src[6])) ||
							(IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && !IsPixEqual(src[0], src[8])) ) );
			
			blendPix = ( DistYCbCr(src[0], src[7]) <= DistYCbCr(src[0], src[1]) ) ? src[7] : src[1];
			dst[ 1] = mix(dst[ 1], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
			dst[ 6] = mix(dst[ 6], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
			dst[ 7] = mix(dst[ 7], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
			dst[ 8] = mix(dst[ 8], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[ 9] = mix(dst[ 9], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
			dst[10] = mix(dst[10], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[11] = mix(dst[11], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
			dst[12] = mix(dst[12], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);
			
			
			dist_01_04 = DistYCbCr(src[5], src[8]);
			dist_03_08 = DistYCbCr(src[7], src[4]);
			haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[8]) && (v[1] != v[8]);
			haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[4]) && (v[3] != v[4]);
			needBlend = (blendResult0 != 0);
			doLineBlend = (  blendResult0 >= 2 ||
						  !((blendResult3 != 0 && !IsPixEqual(src[0], src[8])) ||
							(blendResult1 != 0 && !IsPixEqual(src[0], src[4])) ||
							(IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && !IsPixEqual(src[0], src[6])) ) );
			
			blendPix = ( DistYCbCr(src[0], src[5]) <= DistYCbCr(src[0], src[7]) ) ? src[5] : src[7];
			dst[ 0] = mix(dst[ 0], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
			dst[15] = mix(dst[15], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
			dst[ 4] = mix(dst[ 4], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
			dst[ 5] = mix(dst[ 5], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[ 6] = mix(dst[ 6], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
			dst[ 7] = mix(dst[ 7], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[ 8] = mix(dst[ 8], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
			dst[ 9] = mix(dst[ 9], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);
			
			
			dist_01_04 = DistYCbCr(src[3], src[6]);
			dist_03_08 = DistYCbCr(src[5], src[2]);
			haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[6]) && (v[7] != v[6]);
			haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[2]) && (v[1] != v[2]);
			needBlend = (blendResult3 != 0);
			doLineBlend = (  blendResult3 >= 2 ||
						  !((blendResult2 != 0 && !IsPixEqual(src[0], src[6])) ||
							(blendResult0 != 0 && !IsPixEqual(src[0], src[2])) ||
							(IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && !IsPixEqual(src[0], src[4])) ) );
			
			blendPix = ( DistYCbCr(src[0], src[3]) <= DistYCbCr(src[0], src[5]) ) ? src[3] : src[5];
			dst[ 3] = mix(dst[ 3], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
			dst[12] = mix(dst[12], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
			dst[13] = mix(dst[13], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
			dst[14] = mix(dst[14], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[15] = mix(dst[15], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
			dst[ 4] = mix(dst[ 4], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
			dst[ 5] = mix(dst[ 5], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
			dst[ 6] = mix(dst[ 6], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);
		}
		
		vec4 res = mix( mix( mix( mix(dst[ 6], dst[ 7], step(0.25, f.x)), mix(dst[ 8], dst[ 9], step(0.75, f.x)), step(0.50, f.x)),
		                             mix( mix(dst[ 5], dst[ 0], step(0.25, f.x)), mix(dst[ 1], dst[10], step(0.75, f.x)), step(0.50, f.x)), step(0.25, f.y)),
		                        mix( mix( mix(dst[ 4], dst[ 3], step(0.25, f.x)), mix(dst[ 2], dst[11], step(0.75, f.x)), step(0.50, f.x)),
		                             mix( mix(dst[15], dst[14], step(0.25, f.x)), mix(dst[13], dst[12], step(0.75, f.x)), step(0.50, f.x)), step(0.75, f.y)),
		                                                                                                                                    step(0.50, f.y));


		return res;
}