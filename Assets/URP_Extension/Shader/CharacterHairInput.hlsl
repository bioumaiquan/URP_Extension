#ifndef BIOUM_COMMON_INPUT_INCLUDE
#define BIOUM_COMMON_INPUT_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseMap_ST;
half4 _ShiftMap_ST;
half4 _BaseColor;
half4 _SSSColor;
half4 _EmiColor;
half4 _RimColor;

half _NormalScale;
half _Smoothness;
half _Metallic;
half _AOStrength;

half _FresnelStrength;
half _Transparent;
half _Cutoff;
half _Intensity;

half _SubIntensity;
half _Shift;
half _SubShift;
half _SubSmoothness;

bool _SwitchTangent;
bool _NormalMapDXGLSwitch;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

half4 sampleBaseMap(float2 uv)
{
    half4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    return map * _BaseColor;
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

half2 GetIntensity()
{
    half2 intensity = 0;
    intensity.x = _Intensity;
#if _DOUBLE_SPECULAR
    intensity.y = _SubIntensity;
#endif
    return intensity;
}
half4 GetMask(half2 uv)
{
    half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, uv);
    half ao = LerpWhiteTo(maskMap.a, _AOStrength);
    half2 shift = 0;
    shift.x = _Shift;
#if _DOUBLE_SPECULAR
    shift.y = _SubShift;
#endif
    shift *= (maskMap.r - 0.5);
    return half4(shift, 1, ao);
}
half GetSubSmooth()
{
    half smooth = 0;
#if _DOUBLE_SPECULAR
    smooth = _SubSmoothness;
#endif
    return smooth;
}

#endif //BIOUM_COMMON_INPUT_INCLUDE