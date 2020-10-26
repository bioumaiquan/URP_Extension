#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _RimColor;
half4 _SmoothCurve;

half _NormalScale;
half _AOStrength;
half _FresnelStrength;

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

    map.g = LerpWhiteTo(map.g, _AOStrength);
    map.r = lerp(_SmoothCurve.z, _SmoothCurve.w, map.r);
    map.a = lerp(_SmoothCurve.x, _SmoothCurve.y, map.a);

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

half3 GetSSSColor()
{
    return _SSSColor.rgb;
}

half4 GetRimColor()
{
    return _RimColor;  //alpha = power
}

#endif //BIOUM_COMMON_INPUT_INCLUDE