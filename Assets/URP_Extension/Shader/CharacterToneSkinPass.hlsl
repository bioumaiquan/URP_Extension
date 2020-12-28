#ifndef BIOUM_CHARACTER_TONE_PASS_INCLUDE
#define BIOUM_CHARACTER_TONE_PASS_INCLUDE

#include "../Shader/ShaderLibrary/LightingCharacter.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    real3 normalOS: NORMAL;
    real4 tangentOS: TANGENT;
    real2 texcoord: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real3 vertexSH : TEXCOORD1;
    float4 positionWSAndFog: TEXCOORD2;
    
#if _NORMALMAP
    real4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    real4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    real4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
#else
    real3 normalWS: TEXCOORD3;
    real3 viewDirWS: TEXCOORD4;
#endif
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    real3 VertexLighting: TEXCOORD6;
#endif

#if _RIM
    real3 normalVS : TEXCOORD7;
    real4 viewDirVS : TEXCOORD8;
#endif
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings CommonLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.positionWSAndFog.xyz = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWSAndFog.xyz);
    
    half3 viewDirWS = normalize(_WorldSpaceCameraPos - output.positionWSAndFog.xyz);
#if _NORMALMAP
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);
#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.viewDirWS = viewDirWS;
#endif
    
    output.uv.xy = input.texcoord;
    OUTPUT_GI_SH(output.normalWS.xyz, output.vertexSH);
    
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint vertexLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < vertexLightCount; ++ lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, output.positionWSAndFog.xyz);
        output.VertexLighting += Lambert(light.color, light.direction, output.normalWS.xyz);
    }
#endif
    output.positionWSAndFog.w = ComputeFogFactor(output.positionCS.z);

#if _RIM
    real3 lightDirVS = TransformWorldToViewDir(MainLightDirection(), false);
    output.viewDirVS.xyz = TransformWorldToViewDir(viewDirWS, false);
    output.viewDirVS.w = lightDirVS.x;
    output.normalVS = TransformWorldToViewDir(output.normalWS.xyz, false);
#endif
    
    return output;
}

half4 CommonLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    Surface surface = (Surface)0;
    surface.albedo = sampleBaseMap(input.uv.xy);
    
#if _NORMALMAP
    half3 normalTS = sampleNormalMap(input.uv.xy);
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = mul(normalTS, TBN);
    half3 viewDirWS = half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w);
#else
    half3 normalWS = input.normalWS;
    half3 viewDirWS = input.viewDirWS;
#endif
    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    
    half4 maes = sampleMAESMap(input.uv.xy);
    surface.occlusion = maes.g;
    surface.smoothness = maes.a;
    surface.position = input.positionWSAndFog.xyz;
    surface.SSSColor.rgb = GetSSSColor() * maes.r;
    
    VertexData vertexData = (VertexData)0;
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    vertexData.lighting = input.VertexLighting;
#endif
#if _MAIN_LIGHT_SHADOWS
    vertexData.shadowCoord = TransformWorldToShadowCoord(surface.position);
#endif
    
    half alpha = 1;
    BRDF brdf = GetSimpleBRDF(surface, alpha);
    GI gi = GET_SIMPLE_GI(0, input.vertexSH, surface);

    CharacterParam characterParam;
    characterParam.lightColorBack = _LightColorControl.rgb;
    characterParam.lightIntensity = _LightColorControl.a;
    characterParam.smoothDiff = _SmoothDiff;
    characterParam.rimColorFront = _RimColorFront.rgb;
    characterParam.rimColorBack = _RimColorBack.rgb;
    characterParam.rimOffset = _RimParam.xy;
    characterParam.rimSmooth = _RimParam.z;
    characterParam.rimPower = _RimParam.w;
    
    half3 color = LightingCharacterTone(characterParam, brdf, surface, vertexData, gi);
#if _RIM
    color = ToneRim(characterParam, color, input.normalVS, input.viewDirVS, surface.occlusion);
#endif

    color = MixFog(color, input.positionWSAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_CHARACTER_TONE_PASS_INCLUDE