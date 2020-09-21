Shader "Bioum/Scene/ToneWater"
{
    Properties
    {
        _NormalTex ("法线贴图", 2D) = "bump" {}
        _NormalScale ("高光法线强度", range(0, 2)) = 1
        _EnvNormalScale ("环境反射法线强度", range(0, 1)) = 1

        [Space(20)]
        _Transparent ("整体透明度", range(0, 1)) = 1
        _FresnelPower ("菲涅尔强度", range(0.01, 5)) = 2
        _Smoothness ("光滑度", range(0.8, 1)) = 0.95
        _WaveSpeed ("波浪速度", vector) = (-3, 5, 3, 2)

        [Space(20)]
        _SoftEdgeRange ("边缘透明范围", range(0.01, 10)) = 1
        _WaterColorRange ("浅水区范围", range(0.01, 10)) = 1
        _WaterColorNear ("浅水区颜色", color) = (0.5, 0.8, 0.9, 1)
        _WaterColorFar ("深水区颜色", color) = (0.01, 0.4, 0.8, 1)

        [Space(20)]
        _FoamColor ("泡沫颜色", color) = (1,1,1,1)
        _FoamDensity ("泡沫密度", range(0.01, 100)) = 20
        _FoamSpeed ("泡沫速度", range(0, 10)) = 3
        _ThresholdSpeed ("波浪速度", range(0.01, 5)) = 0.5
        _ThresholdDensity ("波浪密度", range(0.01, 20)) = 5
        _MaxThreshold ("泡沫粗细", range(0.01, 1)) = 0.5
        _ThresholdFalloff ("泡沫距离衰减", range(0.01, 1)) = 0.5
        _FoamEdgeRange ("泡沫边缘透明度", range(0.0, 10)) = 2
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }
        Name "ForwardLit"
        Tags{"LightMode" = "UniversalForward"}
        Lod 300

        Pass
        {
            Blend One OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _REFLECTION_TEXTURE
            #pragma multi_compile_fog
            
            #define _ENABLE_DEPTH_TEXTURE 1
            
            #pragma vertex WaterLitVert
            #pragma fragment WaterLitFrag

            #include "SceneWaterPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }
        Name "ForwardLit"
        Tags{"LightMode" = "UniversalForward"}
        Lod 200

        Pass
        {
            Blend One OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile_fog
            
            #define _ENABLE_DEPTH_TEXTURE 1
            #define _REFLECTION_TEXTURE 0
            
            #pragma vertex WaterLitVert
            #pragma fragment WaterLitFrag

            #include "SceneWaterPass.hlsl"

            ENDHLSL
        }
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True"
        }
        Name "ForwardLit"
        Tags{"LightMode" = "UniversalForward"}
        Lod 100

        Pass
        {
            Blend One OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #define _ENABLE_DEPTH_TEXTURE 0
            #define _REFLECTION_TEXTURE 0
            #pragma multi_compile_fog
            
            #pragma vertex WaterLitVert
            #pragma fragment WaterLitFrag

            #include "SceneWaterPass.hlsl"

            ENDHLSL
        }
    }
}
