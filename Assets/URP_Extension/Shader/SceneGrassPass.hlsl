#ifndef BIOUM_SCENE_GRASS_PASS_INCLUDE
#define BIOUM_SCENE_GRASS_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCommon.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    real3 normalOS: NORMAL;
    real2 texcoord: TEXCOORD0;
    real4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real3 vertexSH : TEXCOORD1;
    float3 positionWS: TEXCOORD2;
        
    real4 VertexLightAndFog: TEXCOORD3; // w: fogFactor, xyz: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD4;
#endif

    real4 waveColor : TEXCOORD5;
    real3 tintColor : TEXCOORD6;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings SimpleLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
#if _WIND
    float2 direction = _WindParam.xy;
    float scale = _WindParam.z;
    float speed = _WindParam.w;
    half2 waveColor = 0;
    float2 wave = PlantsAnimationNoise(output.positionWS, direction, scale, speed, waveColor);
    output.positionWS.xz += wave * input.color.r;
    waveColor.xy = saturate(waveColor.xy);
    output.waveColor.rgb = waveColor.x * waveColor.y * _WaveColor.rgb;
    output.waveColor.a = input.color.r;
#endif

    output.tintColor = lerp(_BaseColor.rgb, _TopColor.rgb, input.color.r);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.uv.xy = input.texcoord;
    
    real3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    OUTPUT_GI_SH(normalWS, output.vertexSH);
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.VertexLightAndFog.rgb = VertexLighting(normalWS, output.positionWS);
#endif
    output.VertexLightAndFog.w = ComputeFogFactor(output.positionCS.z);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
#endif
    
    return output;
}

half4 SimpleLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    half4 tex = sampleBaseMap(input.uv.xy);
#if _ALPHATEST_ON
    #if _DITHER_CLIP
        float dither = GetDither(input.positionCS.xy);
        DitherClip(tex.a, dither, _Cutoff, _DitherCutoff);
    #else
        clip(tex.a - _Cutoff);
    #endif
#endif
    
    VertexData vertexData = (VertexData)0;
    vertexData.lighting = input.VertexLightAndFog.rgb;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    vertexData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    vertexData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
#endif

    half shadow = MainLightRealtimeShadow(vertexData.shadowCoord, input.positionWS);
    
    half alpha = tex.a;    
    half3 color = input.tintColor * shadow;
    color += input.tintColor * input.vertexSH;

    color += input.waveColor.rgb * Square(input.waveColor.a);

    color = MixFog(color, input.VertexLightAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_GRASS_PASS_INCLUDE