#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half _NormalScale;

half _SmoothnessMin;
half _SmoothnessMax;
half _Metallic;
half _AOStrength;

half _FresnelStrength;
half _SpecularTint;
half _Transparent;
half _Cutoff;

bool _NormalMapDXGLSwitch;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_MAESMap); SAMPLER(sampler_MAESMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

half4 sampleBaseMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    return map * _BaseColor;
}

half4 sampleMAESMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_MAESMap, sampler_MAESMap, uv);
    map.r *= _Metallic;
    map.g = LerpWhiteTo(map.g, _AOStrength);
    map.a = lerp(_SmoothnessMin, _SmoothnessMax, map.a);

    return map;
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
    map.y = _NormalMapDXGLSwitch ? 1 - map.y : map.y;
    return UnpackNormalScale(map, _NormalScale);
}

half GetFresnel()
{
    return _FresnelStrength;
}

half GetTransparent()
{
    return _Transparent;
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