#ifndef BIOUM_SCENE_WATER_PASS_INCLUDE
#define BIOUM_SCENE_WATER_PASS_INCLUDE

#include "SceneCommonInput.hlsl"
#include "../Shader/ShaderLibrary/Lighting.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

half4 _WaveSpeed;
sampler2D _NormalTex;

struct Attributes
{
    real4 positionOS: POSITION;
    real2 texcoord: TEXCOORD0;
    real3 normalOS : NORMAL;
    real4 tangentOS : TANGENT;
};

struct Varyings
{
    real4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real3 positionWS: TEXCOORD2;
    real4 tangentWS: TEXCOORD3;
    real4 bitangentWS: TEXCOORD4;
    real4 normalWS: TEXCOORD5;
    
};

Varyings WaterLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    output.uv.xy = input.texcoord + float2(_SinTime.x * _WaveSpeed.x, _SinTime.x * _WaveSpeed.y); 
    output.uv.zw = input.texcoord + float2(_CosTime.y * 1.2 * _WaveSpeed.z, _SinTime.y*0.5* _WaveSpeed.w);

    half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos - output.positionWS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
    
    return output;
}

half4 WaterLitFrag(Varyings input): SV_TARGET
{    
    half4 normalTile = 1;
    //法线贴图  
    half4 bump10 = (tex2D(_NormalTex, input.uv.xy / normalTile) * 2) + (tex2D(_NormalTex, input.uv.zw / normalTile) * 2) - 2;  
    half3 normalTS = bump10.rgb * 2 - 1;
    normalTS.xy *= 0.2;
    normalTS = normalize(normalTS);
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = mul(normalTS, TBN);
    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);


    Surface surface = (Surface)0;
    surface.albedo = 1;
    
    surface.normal = normalWS;
    surface.viewDirection = viewDirWS;
    
    surface.metallic = 0;
    surface.occlusion = 1;
    surface.smoothness = 0.9;
    
    surface.position = input.positionWS;
    surface.fresnelStrength = 1;
    
    VertexData vertexData = (VertexData)0;
    vertexData.lighting = 0;
    
    BRDF brdf = GetBRDF(surface);
    GI gi = GET_GI(0, 0, surface, brdf);
    
    half3 color = LightingPBR(brdf, surface, vertexData, gi);

    return half4(color, 1);
}

#endif // BIOUM_SCENE_WATER_PASS_INCLUDE