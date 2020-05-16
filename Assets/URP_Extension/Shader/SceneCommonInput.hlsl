#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half _BumpScale;
half _SSSBumpScale;
half _Smoothness;
half _Metallic;
half _OcclusionStrength;
half _FresnelStrength;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_MAESMap);
TEXTURE2D(_BumpMap);
TEXTURE2D(_SSSMap);

half4 sampleBaseMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    return map * _BaseColor;
}

half4 sampleMAESMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_MAESMap, sampler_BaseMap, uv);
    map.r *= _Metallic;
    map.g = LerpWhiteTo(map.g, _OcclusionStrength);
    map.a *= _Smoothness;

    return map;
}

half3 sampleBumpMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BumpMap, sampler_BaseMap, uv);
    return UnpackNormalScale(map, _BumpScale);
}

half4 sampleFresnel(float2 uv)
{
    return _FresnelStrength;
}

half3 sampleSSSMap(float2 uv)
{
    half3 map = SAMPLE_TEXTURE2D(_SSSMap, sampler_BaseMap, uv).r * _SSSColor.rgb;
    return map;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE