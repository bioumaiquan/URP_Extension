#ifndef BIOUM_SIMPLELIT_INPUT_INCLUDE
#define BIOUM_SIMPLELIT_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/Noise.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half _NormalScale;
half _AOStrength;
half _Transparent;
half _Cutoff;

bool _NormalMapDXGLSwitch;
half4 _WindParam; //xy:direction z:scale w:speed
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_MAESMap); SAMPLER(sampler_MAESMap);

half4 sampleBaseMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    return map * _BaseColor;
}

half4 sampleMAESMap(float2 uv)
{
    half4 map = 1;
    #if _MAESMAP
        map = SAMPLE_TEXTURE2D(_MAESMap, sampler_MAESMap, uv);
        map.a = LerpWhiteTo(map.a, _AOStrength);
    #endif

    return map;
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
    map.y = _NormalMapDXGLSwitch ? 1 - map.y : map.y;
    return UnpackNormalScale(map, _NormalScale);
}

half GetCutoff()
{
    return _Cutoff;
}

half3 GetSSSColor()
{
    return _SSSColor.rgb;
}

half4 GetRimColor()
{
    return _RimColor;  //alpha = power
}

half GetAlpha()
{
    return _Transparent;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE