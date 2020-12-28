Shader "Bioum/Character/ToneSkin"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}
        [NoScaleOffset]_MAESMap ("(R)SSS (G)AO (A)光滑", 2D) = "white" {}

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0

        _SmoothnessMin("光滑度Min", Range(0.0, 1.0)) = 0
        _SmoothnessMax("光滑度Max", Range(0.0, 1.0)) = 1
        _CurveMin("曲率Min", Range(0.0, 1.0)) = 0
        _CurveMax("曲率Max", Range(0.0, 1.0)) = 1
        _SmoothAndCurve("smooth and curve", vector) = (0,1,0,1)

        _AOStrength("AO强度", Range(0.0, 1.0)) = 1.0
        [Toggle(_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.7, 0.07, 0.01, 1)

        [Toggle(_RIM)] _RimToggle ("RIM开关", float) = 0
        [HDR]_RimColorFront ("边缘光亮面颜色", Color) = (1,1,1,1)
        _RimColorBack ("边缘光暗面颜色", Color) = (0.5, 0.5, 0.5,1)
        _RimSmooth ("边缘光硬度", range(0.001, 0.449)) = 0.1
        _RimPower ("边缘光范围", range(1, 10)) = 5
        _RimOffsetX ("边缘光亮部偏移", range(0, 1)) = 0.4
        _RimOffsetY ("边缘光暗部偏移", range(0, 1)) = 0.4
        _RimParam ("边缘光参数", vector) = (0.4, 0.4, 0.1, 5)

        _LightIntensity ("灯光强度", range(0, 4)) = 1
        _LightColorControl ("暗部颜色", color) = (0.5, 0.5, 0.5, 1)
        _SmoothDiff ("明暗交界线硬度", range(0.001, 1)) = 0.5

    }
    SubShader
    {
        HLSLINCLUDE
            #include "CharacterToneSkinInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _SSS
            #pragma shader_feature _ _RIM
            #pragma multi_compile _ _CHARACTER_IN_UI
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 0

            #include "CharacterToneSkinPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            //#pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "../Shader/ShaderLibrary/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }

    CustomEditor "CharacterToneSkinGUI"
}
