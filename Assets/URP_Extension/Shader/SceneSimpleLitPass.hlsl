#ifndef BIOUM_SCENE_SIMPLELIT_PASS_INCLUDE
#define BIOUM_SCENE_SIMPLELIT_PASS_INCLUDE

#include "../Shader/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float3 positionOS: POSITION;
    real3 normalOS: NORMAL;
    real4 tangentOS: TANGENT;
    real2 texcoord: TEXCOORD0;
    real2 lightmapUV: TEXCOORD1;
    real4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    DECLARE_GI_DATA(lightmapUV, vertexSH, 1);
    float3 positionWS: TEXCOORD2;
    
#if _NORMALMAP
    real4 tangentWS: TEXCOORD4;    // xyz: tangent, w: viewDir.x
    real4 bitangentWS: TEXCOORD5;    // xyz: binormal, w: viewDir.y
    real4 normalWS: TEXCOORD3;    // xyz: normal, w: viewDir.z
#else
    real3 normalWS: TEXCOORD3;
    real3 viewDirWS: TEXCOORD4;
#endif
    
    real4 VertexLightAndFog: TEXCOORD6; // w: fogFactor, xyz: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD7;
#endif
    
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
    float2 wave = PlantsAnimationNoise(output.positionWS, direction, scale, speed);
    output.positionWS.xz += wave * input.color.r;
#endif
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    half3 viewDirWS = _WorldSpaceCameraPos - output.positionWS;
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
    for (uint lightIndex = 0u; lightIndex < vertexLightCount; ++ lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, output.positionWS);
        output.VertexLightAndFog.rgb += Lambert(light.color, light.direction, output.normalWS.xyz);
    }
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
    
    Surface surface = (Surface)0;
    surface.albedo = sampleBaseMap(input.uv.xy);
    #if _ALPHATEST_ON
        clip(surface.albedo.a - _Cutoff);
    #endif
    
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
    surface.occlusion = maes.a;
    surface.position = input.positionWS;
    surface.SSSColor = GetSSSColor();

    half3 emissive = maes.r * _EmiColor.rgb;
    half4 rimColor = GetRimColor();

    VertexData vertexData = (VertexData)0;
    vertexData.lighting = input.VertexLightAndFog.rgb;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    vertexData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    vertexData.shadowCoord = TransformWorldToShadowCoord(surface.position);
#endif
    
    half alpha = GetAlpha() * surface.albedo.a;
    GI gi = GET_SIMPLE_GI(input.lightmapUV, input.vertexSH, surface);
    
    half3 color = LightingLambert(surface, vertexData, gi, rimColor);
    color += emissive;

#if GREY
    color = Luminance(color);
#endif

    color = MixFog(color, input.VertexLightAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_COMMON_PASS