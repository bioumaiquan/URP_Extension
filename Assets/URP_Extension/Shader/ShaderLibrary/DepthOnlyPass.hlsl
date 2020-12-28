#ifndef BIOUM_DEPTH_ONLY_PASS_INCLUDED
#define BIOUM_DEPTH_ONLY_PASS_INCLUDED

#if _ALPHATEST_ON || _DITHER_CLIP
#define SHOULD_SAMPLE_TEXTURE
#endif

struct Attributes
{
    float4 positionOS     : POSITION;
    float2 texcoord     : TEXCOORD0;
    real4 color     : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    #ifdef SHOULD_SAMPLE_TEXTURE
    float2 uv           : TEXCOORD0;
    #endif
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    #ifdef SHOULD_SAMPLE_TEXTURE
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    #endif
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    #if _WIND
        float2 direction = _WindParam.xy;
        float scale = _WindParam.z;
        float speed = _WindParam.w;
        float2 wave = PlantsAnimationNoise(positionWS, direction, scale, speed);
        positionWS.xz += wave * input.color.r;
    #endif
    output.positionCS = TransformWorldToHClip(positionWS);
    return output;
}

half4 DepthOnlyFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#ifdef SHOULD_SAMPLE_TEXTURE
    float alpha = sampleBaseMap(input.uv).a;
#endif

#if _ALPHATEST_ON
    #if _DITHER_CLIP
        float dither = GetDither(input.positionCS.xy);
        DitherClip(alpha, dither, _Cutoff, _DitherCutoff);
    #else
        clip(alpha - _Cutoff);
    #endif
#endif

   // Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}
#endif
