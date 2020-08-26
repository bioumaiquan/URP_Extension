#ifndef BIOUM_SCENE_WATER_PASS_INCLUDE
#define BIOUM_SCENE_WATER_PASS_INCLUDE

#include "../Shader/ShaderLibrary/Common.hlsl"
#include "../Shader/ShaderLibrary/Surface.hlsl"
#include "../Shader/ShaderLibrary/Lighting.hlsl"
#include "../Shader/ShaderLibrary/Fog.hlsl"

sampler2D _NormalTex; 
CBUFFER_START(UnityPerMaterial)
half4 _WaveSpeed;
half4 _NormalTex_ST;
half _NormalScale, _EnvNormalScale;
half _SoftEdgeRange, _WaterColorRange;
half4 _WaterColorNear, _WaterColorFar;
half _Transparent;
half _FresnelPower;
half _Smoothness;

half _ThresholdSpeed;
half _ThresholdDensity;
half _MaxThreshold;
half _ThresholdFalloff;
half _FoamDensity;
half _FoamSpeed;
half _FoamEdgeRange;
half4 _FoamColor;
CBUFFER_END

struct Attributes
{
    float4 positionOS: POSITION;
    real2 texcoord: TEXCOORD0;
    real3 normalOS : NORMAL;
    real4 tangentOS : TANGENT;
    half4 color : COLOR;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    real4 uv: TEXCOORD0;
    real3 positionWS: TEXCOORD1;
    real4 tangentWS: TEXCOORD2;
    real4 bitangentWS: TEXCOORD3;
    real4 normalWS: TEXCOORD4;
    real4 positionSS: TEXCOORD5;
    half4 vColor : COLOR; 
};

Varyings WaterLitVert(Attributes input)
{
    Varyings output = (Varyings)0;
    
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    
    half4 uv = input.texcoord.xyxy * _NormalTex_ST.xyxy * half4(1,1,1.3,1.28);
    output.uv = uv + _Time.x * _WaveSpeed; 

    half3 viewDirWS = _WorldSpaceCameraPos.xyz - output.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.x);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.y);
    output.normalWS = half4(normalInput.normalWS, viewDirWS.z);

    output.positionSS = ComputeScreenPos(output.positionCS);

#if !_ENABLE_DEPTH_TEXTURE
    half2 range = rcp(half2(_WaterColorRange, _SoftEdgeRange) * 0.1);
    range = smoothstep(0, 1, range * input.color.r);
    output.vColor = lerp(_WaterColorNear, _WaterColorFar, range.x);
    output.vColor.a = range.y;
#endif

    return output;
}

real near(real delta, real value, real target)
{
    return (delta - min(delta, abs(value - target))) / delta;
}
real bin(real value)
{
    return log(1 + value * 1000.0);
}
real nearBin(real delta, real value, real target)
{
    return bin(near(delta, value, target));
}


half4 WaterLitFrag(Varyings input): SV_TARGET
{    
    half4 bump0 = tex2D(_NormalTex, input.uv.xy);
    half4 bump1 = tex2D(_NormalTex, input.uv.zw);

    //base color and alpha
    half3 color = 1; half alpha = 1; half edge = 1;
    #if _ENABLE_DEPTH_TEXTURE
        half3 far = rcp(half3(_SoftEdgeRange, _WaterColorRange, _FoamEdgeRange));
        half3 positionNDC = input.positionSS.xyz / input.positionSS.w;
        float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, positionNDC.xy).r;
        half sceneZ = LinearEyeDepth(depth, _ZBufferParams);
        half thisZ = LinearEyeDepth(positionNDC.z, _ZBufferParams);
        edge = sceneZ - thisZ;
        half3 fade = saturate (far * edge);
        edge = fade.z; //use for foam

        color = lerp(_WaterColorNear.rgb, _WaterColorFar.rgb, fade.y);
        alpha = fade.x;
    #else
        color = input.vColor.rgb;
        edge = alpha = input.vColor.a;
    #endif
    half foamEdge = edge;//saturate(lerp(0, _FoamEdgeRange, edge));

    half3 normalTS = bump0.xyz + bump1.xyz - 1;  // ((bump0 * 2 - 1) + (bump1 * 2 - 1)) / 2
    normalTS.xy *= _NormalScale;
    half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    half3 normalWS = SafeNormalize(mul(normalTS, TBN));
    half3 viewDirWS = SafeNormalize(half3(input.tangentWS.w, input.bitangentWS.w, input.normalWS.w));

    half3 envNormal = lerp(input.normalWS.xyz, normalWS, _EnvNormalScale);

    Surface surface = (Surface)0;
    surface.albedo = color;
    surface.normal = normalWS;
    surface.viewDirection = viewDirWS;
    surface.metallic = 0;
    surface.occlusion = 1;
    surface.smoothness = _Smoothness;
    surface.position = input.positionWS;
    surface.fresnelStrength = 1;
    surface.specularStrength = 1;
    surface.specularTint = 1;

    half fresnel = 1 - max(0, dot(envNormal, surface.viewDirection));
    fresnel = pow(fresnel, _FresnelPower);
    alpha *= fresnel;
    alpha *= _Transparent;

    //lighting
    Light light = GetMainLight();
    BRDF brdf = GetBRDF(surface);
    half3 specColor = SpecularStrength(surface, brdf, light) * light.color;
    surface.normal = envNormal;
    half3 envReflection = SampleEnvironment (surface, brdf);

    //wave
    half threshold = positiveSin((surface.position.x + _Time.y * _ThresholdSpeed) * _ThresholdDensity);
    threshold *= _MaxThreshold * (_ThresholdFalloff - edge);
    half wave = positiveSin(edge * _FoamDensity - _Time.y * _FoamSpeed);
    wave = saturate(nearBin(threshold, wave, 1) + nearBin(threshold, edge, 0));
    wave *= foamEdge * _FoamColor;

    //final color
    color += specColor;
    color += color * envReflection;
    color *= alpha;
    color += wave;

    return half4(color, alpha);
}

#endif // BIOUM_SCENE_WATER_PASS_INCLUDE