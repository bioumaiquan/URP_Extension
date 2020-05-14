#ifndef BIOUM_FOG_INCLUDE
#define BIOUM_FOG_INCLUDE

half4 Bioum_FogColor;
half4 Bioum_FogSunColor;

// x = start distance
// y = distance falloff
// z = start height 
// w = height falloff
half4 Bioum_FogParam;

// x = strength
// y = range
half4 Bioum_FogScatteringParam;


//distance exp fog and height exp fog
//http://www.iquilezles.org/www/articles/fog/fog.htm
half ComputeFogFactor(half3 positionWS, half fogStrength) 
{
    float fogFactor = 0;
    #if defined(BIOUM_FOG_SIMPLE) || defined(BIOUM_FOG_HEIGHT)
        #ifdef BIOUM_FOG_SIMPLE
            float dis = distance(_WorldSpaceCameraPos.xyz, positionWS);
            float disFogFactor = max(0, 1 - exp(-(dis - Bioum_FogParam.x) * Bioum_FogParam.y));
            fogFactor = disFogFactor;
        #endif

        #ifdef BIOUM_FOG_HEIGHT
            float heightFogFactor = max(0, 1 - exp((positionWS.y - Bioum_FogParam.z) * Bioum_FogParam.w));
            fogFactor = heightFogFactor;
        #endif

        #if defined(BIOUM_FOG_SIMPLE) && defined(BIOUM_FOG_HEIGHT)
            fogFactor = lerp(heightFogFactor * disFogFactor, saturate(disFogFactor + heightFogFactor), disFogFactor);
        #endif

        fogFactor += fogStrength - 1;
    #endif

    return saturate(fogFactor);
}
half3 GetScatteringColor(half3 lightDir, half3 lightColor, half3 viewDirWS)
{
    half sun = max(0, dot(-lightDir, viewDirWS));
    sun = pow(sun, Bioum_FogScatteringParam.y);
    sun *= Bioum_FogScatteringParam.x;
    return lightColor.rgb * sun;
}
half3 MixFogColor(half3 fogColor, half3 color, half fogFactor, half3 viewDirWS)
{
    #if defined(BIOUM_FOG_SIMPLE) || defined(BIOUM_FOG_HEIGHT)
        #if defined(BIOUM_FOG_SCATTERING)
            half3 lightDir = _DirectionalLightDirections[0].xyz;
            half3 lightColor = _DirectionalLightColors[0].rgb;
            half3 scatteringColor = GetScatteringColor(lightDir, lightColor, viewDirWS);
            fogColor += scatteringColor;
        #endif
        return lerp(color, fogColor, fogFactor);
    #endif
    return color;
}
half3 MixFogColor(half3 color, half fogFactor, half3 viewDirWS)
{
    return MixFogColor(Bioum_FogColor.rgb, color, fogFactor, viewDirWS);
}

//fog end

#endif  //BIOUM_FOG_INCLUDE