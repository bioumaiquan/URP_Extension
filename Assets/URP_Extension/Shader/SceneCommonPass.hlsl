#ifndef BIOUM_SCENE_COMMON_PASS_INCLUDE
#define BIOUM_SCENE_COMMON_PASS_INCLUDE

#include "SceneCommonInput.hlsl"
#include "../Shader/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    real4 positionOS   : POSITION;
    real3 normalOS     : NORMAL;
    real4 tangentOS    : TANGENT;
    real2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS               : SV_POSITION;
    real2 uv                       : TEXCOORD0;
    half3 vertexSH                 : TEXCOORD1;
    real3 positionWS               : TEXCOORD2;

#ifdef _NORMALMAP
    real4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
    real4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    real4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    real3 normalWS                 : TEXCOORD3;
    real3 viewDirWS                : TEXCOORD4;
#endif

    real4 VertexLightAndFog        : TEXCOORD6; // w: fogFactor, xyz: vertex light

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings CommonLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input,output);

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    //output.viewAndFog.xyz = SafeNormalize(_WorldSpaceCameraPos - output.positionWS);
    //output.VertexLightAndFog.rgb = ComputeFogFactor(output.positionWS, 1);
    output.VertexLightAndFog.w = ComputeFogFactor(output.positionWS, 1);

    output.normalWS = TransformObjectToWorldNormal(input.normalOS);

    return output;
}

half4 CommonLitFrag(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
	
    Surface surface = (Surface)0;
    surface.albedo = 0.5;
    surface.normal = SafeNormalize(input.normalWS);
    surface.metallic = 0;
    surface.smoothness = 0.6;

    BRDF brdf = GetBRDF(surface);
    GI gi = GetGI(0, surface, brdf);

    half3 color = LightingPBR(brdf, surface, gi);

    return half4(color, 1);
}


#endif  // BIOUM_SCENE_COMMON_PASS