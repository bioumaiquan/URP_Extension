#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half4 _SmoothAndCurve;

half _NormalScale;
half _AOStrength;
half _SmoothDiff;

half4 _LightColorControl;
half4 _RimColorFront;
half4 _RimColorBack;
half4 _RimParam;

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

    map.r = lerp(_SmoothAndCurve.z, _SmoothAndCurve.w, map.r);
    map.g = LerpWhiteTo(map.g, _AOStrength);
    map.a = lerp(_SmoothAndCurve.x, _SmoothAndCurve.y, map.a);

    return map;
}

half3 sampleNormalMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
    //map.y = _NormalMapDXGLSwitch ? 1 - map.y : map.y;
    return UnpackNormalScale(map, _NormalScale);
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