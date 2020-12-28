#ifndef BIOUM_SHADOW_CASTER_PASS_INCLUDED
#define BIOUM_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

#if _ALPHATEST_ON || _DITHER_CLIP || _DITHER_TRANSPARENT
#define SHOULD_SAMPLE_TEXTURE
#endif


float3 _LightDirection;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
#ifdef SHOULD_SAMPLE_TEXTURE
    float2 texcoord     : TEXCOORD0;
#endif
#if _WIND
    real4 color : COLOR;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
#ifdef SHOULD_SAMPLE_TEXTURE
    float2 uv           : TEXCOORD0;
#endif
    float4 positionCS   : SV_POSITION;
};



float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    float2 wave = PlantsAnimationNoise(positionWS, direction, scale, speed);
    positionWS.xz += wave * input.color.r;
#endif
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

#ifdef SHOULD_SAMPLE_TEXTURE
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
#endif

    output.positionCS = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
#ifdef SHOULD_SAMPLE_TEXTURE
    float alpha = sampleBaseMap(input.uv).a;
#endif

#if _ALPHATEST_ON && !_DITHER_CLIP              // 常规cutout
    clip(alpha - _Cutoff);
#elif _DITHER_CLIP && !_DITHER_TRANSPARENT      // cutout并且开启dither
    float dither = GetDither(input.positionCS.xy);
    DitherClip(alpha, dither, _Cutoff, _DitherCutoff);
#elif _DITHER_CLIP && _DITHER_TRANSPARENT       // 半透并且开启dither
    alpha *= _Transparent;
    float dither = GetDither(input.positionCS.xy);
    clip(alpha - dither);
#endif
    //Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}

#endif
