#ifndef BIOUM_UNLIT_INPUT_INCLUDE
#define BIOUM_UNLIT_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _BaseColor;
half4 _RimColor;
half _Transparent;
half _Cutoff;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

half4 sampleBaseMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    return map * _BaseColor;
}

half GetAlpha()
{
    return _Transparent;
}

half GetCutoff()
{
    return _Cutoff;
}

half4 GetRim()
{
    return _RimColor;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE