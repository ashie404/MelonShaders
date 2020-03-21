
uniform int worldTime;
uniform vec3 cameraPosition;
uniform sampler2D noisetex;

const float PI = 3.1415927;

float calcWaterMove(vec3 worldpos)
{
    float fy = fract(worldpos.y + 0.005);
		
    if(fy > 0.01){
    float wave = sin(2 * PI * (worldTime*0.7 + worldpos.x * 0.14 + worldpos.z * 0.07))
                + sin(2 * PI * (worldTime*0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
    return wave * 0.05;
    } else return 0.0;
}

vec3 WavingWater(vec3 position)
{
    vec3 wave = vec3(0.0);
    vec3 worldpos = position + cameraPosition;
    wave.y += calcWaterMove(worldpos);
    return wave;
}