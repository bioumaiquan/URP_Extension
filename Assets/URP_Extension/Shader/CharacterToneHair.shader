Shader "Bioum/Character/ToneHair"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}
        [NoScaleOffset]_MAESMap ("(R)AO (A)偏移", 2D) = "white" {}

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0

        _Smoothness("光滑度", Range(0.0, 1.0)) = 0.9
        _Metallic("金属度调整", Range(0.0, 1.0)) = 0.0
        _AOStrength("AO强度", Range(0.0, 1.0)) = 0.0
        _FresnelStrength("菲涅尔强度", Range(0.0, 1.0)) = 1.0
        _Cutoff("cutoff", Range(0.0, 1.0)) = 0.5

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

        [Toggle]_ToneMapping("Tone Mapping", float) = 1.0
        [Toggle(_DOUBLE_SPECULAR)] _DoubleSpecular("Double Specular", float) = 0
        [Toggle(_SWITCH_TANGENT)] _SwitchTangent("switch Tangent", float) = 1

        _SpecIntensity("_Intensity", range(0,1)) = 0.5
        _Shift("_Shift", range(-1,1)) = 0
        _SubSmoothness("_SubSmoothness", range(0,1)) = 0.5
        _SubSpecIntensity("_SubIntensity", range(0,0.5)) = 0.25
        _SubShift("_SubShift", range(-1,1)) = 0

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        HLSLINCLUDE
            #include "CharacterToneHairInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            ZWrite On Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            #pragma shader_feature _ _ALPHATEST_ON
            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _SSS
            #pragma shader_feature _ _RIM
            #pragma shader_feature _ _DOUBLE_SPECULAR
            #pragma shader_feature _ _SWITCH_TANGENT
            #pragma multi_compile _ _CHARACTER_IN_UI
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 1

            #include "CharacterToneHairPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull[_Cull] ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON
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
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma shader_feature _ALPHATEST_ON

            #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }

    CustomEditor "CharacterToneHairGUI"
}
