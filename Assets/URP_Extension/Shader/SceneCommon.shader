Shader "Bioum/Scene/Common"
{
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseMap ("Main Tex", 2D) = "white" {}
        _MAESMap ("MAES Tex", 2D) = "white" {}

        [Toggle(_NORMALMAP)] _NormalMap("NORMAL MAP", float) = 0
        _BumpMap ("Normal Tex", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(-2.0, 2.0)) = 1.0

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _OcclusionStrength("Occlusion", Range(0.0, 1.0)) = 1.0
        _FresnelStrength("Fresnel Strength", Range(0.0, 1.0)) = 1.0

        [Space(10)]
        [Toggle(_SSS)] _sss ("SSS", float) = 0
        _SSSColor ("SSS Color", Color) = (0.7, 0.07, 0.01, 1)
        _SSSBumpScale ("SSS Normal Scale", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            //Blend [_SrcBlend] [_DstBlend]
            //ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_instancing

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _SSS
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #include "SceneCommonPass.hlsl"
            ENDHLSL
        }


        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "SceneCommonInput.hlsl"
            #include "../Shader/ShaderLibrary/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "SceneCommonInput.hlsl"
            #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}
