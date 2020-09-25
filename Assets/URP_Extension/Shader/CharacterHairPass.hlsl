#ifndef BIOUM_SCENE_COMMON_PASS_INCLUDE
#define BIOUM_SCENE_COMMON_PASS_INCLUDE

#include "../Shader/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    real4 positionOS: POSITION;
    real3 normalOS: NORMAL;
    real4 tangentOS: TANGENT;
    real2 texcoord: TEXCOORD0;
    real2 lightmapUV: TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real3 vertexSH : TEXCOORD1;
    real3 positionWS: TEXCOORD2;
    
    real4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    real4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    real4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
    
    real4 VertexLightAndFog: TEXCOORD6; // w: fogFactor, xyz: vertex light

#if _MAIN_LIGHT_SHADOWS
    real4 shadowCoord : TEXCOORD7;
#endif
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings CommonLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    half3 viewDirWS = _WorldSpaceCameraPos - output.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
    
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.uv.zw = TRANSFORM_TEX(input.texcoord, _ShiftMap);
    
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint vertexLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < vertexLightCount; ++ lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, output.positionWS);
        output.VertexLightAndFog.rgb += Lambert(light.color, light.direction, output.normalWS.xyz);
    }
#endif
    output.VertexLightAndFog.w = ComputeFogFactor(output.positionCS.z);

#if _MAIN_LIGHT_SHADOWS
    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
#endif
    
    return output;
}

half4 CommonLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    Surface surface = (Surface)0;
    surface.albedo = sampleBaseMap(input.uv.xy);
    #if _ALPHATEST_ON
        clip(surface.albedo.a - _Cutoff);
    #endif
    
#if _NORMALMAP
    half3 normalTS = sampleNormalMap(input.uv.xy);
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = mul(normalTS, TBN);
#else
    half3 normalWS = input.normalWS;
#endif

    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
    half3 tangentWS = _SwitchTangent ? input.bitangentWS.xyz : input.tangentWS.xyz;
    tangentWS = SafeNormalize(tangentWS);

    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    
    half4 maskMap = GetMask(input.uv.xy);
    surface.metallic = _Metallic;
    surface.occlusion = maskMap.w;
    surface.smoothness = _Smoothness;
    surface.specularTint = 0.5;
    surface.position = input.positionWS;
    surface.fresnelStrength = GetFresnel();
    surface.SSSColor = GetSSSColor();

    half4 rimColor = GetRimColor();

    
    VertexData vertexData = (VertexData)0;
    vertexData.lighting = input.VertexLightAndFog.rgb;
#if _MAIN_LIGHT_SHADOWS
    vertexData.shadowCoord = input.shadowCoord;
#endif
    
    half alpha = GetAlpha() * surface.albedo.a;
    BRDF brdf = GetBRDF(surface, alpha);
    GI gi = GET_GI(input.lightmapUV, input.vertexSH, surface, brdf);
    
    half2 shift = maskMap.xy;
    half2 intensity = GetIntensity();
    half subSmoothness = GetSubSmooth();
    
    half3 color = LightingHair(brdf, surface, gi, vertexData, tangentWS, shift, intensity, subSmoothness, rimColor);

    color = MixFog(color, input.VertexLightAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_COMMON_PASS