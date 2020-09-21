#ifndef BIOUM_SCENE_UNLIT_PASS_INCLUDE
#define BIOUM_SCENE_UNLIT_PASS_INCLUDE

struct Attributes
{
    real4 positionOS: POSITION;
    real2 texcoord: TEXCOORD0;
    real3 normalOS: NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    real4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real4 vertexSHAndFog : TEXCOORD1;   
    #if _RIM
        real3 viewDirWS : TEXCOORD2;
        real3 normalWS : TEXCOORD3;
    #endif 
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings UnlitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(positionWS);
    
    #if _RIM
        output.viewDirWS = _WorldSpaceCameraPos - positionWS;
        output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    #endif
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
        
    return output;
}

half4 UnlitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    half4 albedo = sampleBaseMap(input.uv.xy);
    #if _ALPHATEST_ON
        clip(albedo.a - GetCutoff());
    #endif

    half3 color = albedo.rgb;
    half alpha = GetAlpha() * albedo.a;
    #if _ALPHAPREMULTIPLY_ON
        color *= alpha;
    #endif

    #if _RIM
        half4 rimColor = GetRim();
        half3 viewDirWS = SafeNormalize(input.viewDirWS);
        half3 normalWS = SafeNormalize(input.normalWS);
        half NdotV = saturate(dot(normalWS, viewDirWS));
        half rim = PositivePow(1 - NdotV, rimColor.a);
        color += rim * rimColor.rgb;
    #endif

    color = MixFog(color, input.vertexSHAndFog.w);
    
    return half4(color, alpha);
}


#endif // BIOUM_SCENE_COMMON_PASS