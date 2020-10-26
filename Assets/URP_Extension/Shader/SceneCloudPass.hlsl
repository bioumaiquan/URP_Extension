#ifndef BIOUM_SCENE_SIMPLELIT_PASS_INCLUDE
#define BIOUM_SCENE_SIMPLELIT_PASS_INCLUDE

#include "../Shader/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    real3 normalOS: NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    half3 color: TEXCOORD0;
        
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#if _NOISE
half4 g_NoiseParam; // x:Amplitude y:Frequency z:Offset
real3 displace(real3 p)
{
    real3 q = normalize(cross(p, real3(0, 1, 0)) + real3(0, 1e-5, 0));
    real3 r = cross(p, q);
    real3 n = snoise3D_grad(p * g_NoiseParam.y + g_NoiseParam.z).xyz * g_NoiseParam.x;
    return p * (1 + n.x) + q * n.y + r * n.z;
}
#endif

Varyings CloudLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
#if _NOISE
    input.positionOS.xyz = displace(input.positionOS.xyz);
#endif

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(positionWS);
    
    real3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    real3 viewDirWS = _WorldSpaceCameraPos - positionWS;
    

    Surface surface = (Surface)0;
    surface.albedo = _BaseColor;
    surface.normal = SafeNormalize(normalWS);
    surface.viewDirection = SafeNormalize(viewDirWS);
    surface.occlusion = 1;
    surface.position = positionWS;

    GI gi = GET_SIMPLE_GI(0, SampleSH(normalWS), surface);
    
    half3 color = LightingLambert(surface, (VertexData)0, gi, half4(_RimColor.rgb, _RimPower));
    color += _EmiColor.rgb;
    color = MixFog(color, ComputeFogFactor(output.positionCS.z));

    output.color = color;
    
    return output;
}

half4 CloudLitFrag(Varyings input): SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    return half4(input.color, 1);
}


#endif // BIOUM_SCENE_COMMON_PASS