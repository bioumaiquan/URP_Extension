#ifndef BIOUM_SCENE_COMMON_PASS_INCLUDE
#define BIOUM_SCENE_COMMON_PASS_INCLUDE

#include "SceneCommonInput.hlsl"
#include "../Shader/ShaderLibrary/Lighting.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

struct Attributes
{
    real4 positionOS   : POSITION;
    real3 normalOS     : NORMAL;
    real4 tangentOS    : TANGENT;
    real2 texcoord     : TEXCOORD0;
    real2 lightmapUV     : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS               : SV_POSITION;
    real4 uv                       : TEXCOORD0;
    DECLARE_GI_DATA(lightmapUV, vertexSH, 1);
    real3 positionWS               : TEXCOORD2;

#ifdef _NORMALMAP
    real4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.x
    real4 bitangentWS              : TEXCOORD5;    // xyz: binormal, w: viewDir.y
    real4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.z
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

    half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos - output.positionWS);
    #if _NORMALMAP
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
        output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
    #else
        output.normalWS = TransformObjectToWorldNormal(input.normalOS);
        output.viewDirWS = viewDirWS;
    #endif

    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);

    OUTPUT_GI_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        uint vertexLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < vertexLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, output.positionWS);
            output.VertexLightAndFog.rgb += Lambert(light.color, light.direction, output.normalWS.xyz);
        }
    #endif
    output.VertexLightAndFog.w = ComputeFogFactor(output.positionWS, 1);

    return output;
}

half4 CommonLitFrag(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
	
    Surface surface = (Surface)0;
    surface.albedo = sampleBaseMap(input.uv.xy).rgb;

    #if _NORMALMAP
        half3 normalTS = sampleBumpMap(input.uv.xy);
        half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
        half3 normalWS = mul(normalTS, TBN);
        half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
        half3 originalNormal = input.normalWS.xyz;
    #else
        half3 normalWS = input.normalWS;
        half3 viewDirWS = input.viewDirWS;
        half3 originalNormal = normalWS;
    #endif
    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = viewDirWS;

    half4 maes = sampleMAESMap(input.uv.xy);
    surface.metallic = maes.r;
    surface.occlusion = maes.g;
    surface.smoothness = maes.a;

    surface.position = input.positionWS;
    surface.fresnelStrength = sampleFresnel(input.uv.xy).r;

    #ifdef _SSS
        surface.SSSNormal = lerp(originalNormal, surface.normal, _SSSBumpScale);
        surface.SSSColor = _SSSColor.rgb;
    #endif

    VertexData vertexData = (VertexData)0;
    vertexData.lighting = input.VertexLightAndFog.rgb;

    BRDF brdf = GetBRDF(surface);
    GI gi = GET_GI(input.lightmapUV, input.vertexSH, surface, brdf);

    half3 color = LightingPBR(brdf, surface, vertexData, gi);

    return half4(color, 1);
}


#endif  // BIOUM_SCENE_COMMON_PASS