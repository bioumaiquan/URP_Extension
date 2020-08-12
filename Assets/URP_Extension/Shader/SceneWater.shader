Shader "Bioum/Scene/Water"
{
    Properties
    {
        _NormalTex ("Normal Tex", 2D) = "bump" {}
        _WaveSpeed ("Wave Speed", vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Name "ForwardLit"
        Tags{"LightMode" = "UniversalForward"}

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            //Blend [_SrcBlend] [_DstBlend]
            //ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            
            #pragma vertex WaterLitVert
            #pragma fragment WaterLitFrag

            #include "SceneWaterPass.hlsl"

            ENDHLSL
        }
    }
}
