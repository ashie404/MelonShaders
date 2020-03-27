/*float calcSSS( in vec3 pos, in vec3 nor )
{
    float ao = 1.0;
    float totao = 0.0;
    float sca = 1.0;
    for( int aoi=0; aoi<5; aoi++ )
    {
        float hr = 0.01 + 0.4*float(aoi)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = aopos.x;
        totao += (hr-min(dd,0.0))*sca;
        sca *= 0.9;
    }
    return pow( clamp( 1.2 - 0.25*totao, 0.0, 1.0 ), 16.0 );
}*/

float power = 1;
float scale = 2;

float calcSSS(in vec3 viewPos, in vec3 normal, in vec3 lightVec) {
    // very basic subsurface scattering
    float strength = 0;

    vec3 H = normalize(-lightVec + normal);
    strength = pow(clamp01(dot(viewPos, -H)), power) * scale;

    return strength;
}