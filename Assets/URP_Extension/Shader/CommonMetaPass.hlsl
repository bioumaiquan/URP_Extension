#ifndef COMMOM_META_PASS_INCLUDED
#define COMMOM_META_PASS_INCLUDED


#include "../Shader/ShaderLibrary/Lighting.hlsl"
#include "../Shader/ShaderLibrary/BRDF.hlsl"
#include "../Shader/ShaderLibrary/GI.hlsl"

struct Attributes 
{
    float3 positionOS : POSITION;
    float2 texcoord : TEXCOORD0;
    float2 lightMapUV : TEXCOORD1;
};

struct Varyings 
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
};

Varyings MetaPassVertex (Attributes input) 
{
    Varyings output;
    input.positionOS.xy = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    input.positionOS.z = input.positionOS.z > 0.0 ? HALF_MIN : 0.0;
    output.positionCS = TransformWorldToHClip(input.positionOS);
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    return output;
}

bool4 unity_MetaFragmentControl;
float unity_OneOverOutputBoost;
float unity_MaxOutputValue;
float4 MetaPassFragment (Varyings input) : SV_TARGET 
{
    Surface surface = (Surface)0;
    surface.albedo = sampleBaseMap(input.uv);

    half4 maes = sampleMAESMap(input.uv);
    surface.metallic = maes.r;
    surface.smoothness = maes.a;
    half alpha = surface.albedo.a;
    BRDF brdf = GetBRDF(surface, alpha);
    float4 meta = 0;
    if (unity_MetaFragmentControl.x) 
    {
        meta = float4(brdf.diffuse, alpha);
        meta.rgb += brdf.specular * brdf.roughness * 0.5;
        meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
    }
    else if (unity_MetaFragmentControl.y) 
    {
        meta = float4(_EmiColor.rgb * maes.b, alpha);
    }
    return meta * _Transparent;
}

#endif