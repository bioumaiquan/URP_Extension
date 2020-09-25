Shader "Bioum/Scene/CommonLit"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [HDR]_EmiColor("自发光颜色", Color) = (0,0,0,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}
        [NoScaleOffset]_MAESMap ("(R)金属 (G)AO (B)自发光 (A)光滑", 2D) = "white" {}

        _Cutoff("透贴强度", Range(0.0, 1.0)) = 0.5
        _Transparent("透明度", Range(0.0, 1.0)) = 1

        [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Range(-2.0, 2.0)) = 1.0
        [Toggle] _NormalMapDXGLSwitch ("OpenGL/DX Switch", float) = 0

        _SmoothnessMin("光滑度Min", Range(0.0, 1.0)) = 0
        _SmoothnessMax("光滑度Max", Range(0.0, 1.0)) = 1
        _Metallic("金属度调整", Range(0.0, 1.0)) = 0.0
        _AOStrength("AO强度", Range(0.0, 1.0)) = 1.0
        _FresnelStrength("菲涅尔强度", Range(0.0, 1.0)) = 1.0
        _SpecularTint("非金属反射着色", Range(0.0, 1.0)) = 0.0

        [Toggle(_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.7, 0.07, 0.01, 1)

        [HDR]_RimColor ("边缘光颜色", Color) = (0,0,0,1)
        _RimPower ("边缘光范围", range(1, 20)) = 4

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _SrcBlend ("_SrcBlend", float) = 1
        [HideInInspector] _DstBlend ("_DstBlend", float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", float) = 1
        [HideInInspector][Toggle] _TransparentZWrite ("_TransparentZWrite", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
        [HideInInspector] _Color("Color", Color) = (1,1,1,1)
        [HideInInspector] _MainTex ("Main Tex", 2D) = "white" {}
    }
    SubShader
    {
        HLSLINCLUDE
            #include "SceneCommonInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite] Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _SHADOWS_SOFT
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _SSS
            #pragma shader_feature _ _RIM
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 1
            #define _ADDITIONAL_LIGHTS 1

            #include "SceneCommonPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull Off ColorMask 0

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
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "CommonMetaPass.hlsl"
            ENDHLSL
        }
    }

    SubShader
    {
        HLSLINCLUDE
            #include "SceneCommonInput.hlsl"
        ENDHLSL
        
        LOD 200
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite] Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.5

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _SHADOWS_SOFT
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _RIM
            #pragma shader_feature _ _SSS
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #define _SPECULAR_ON 1
            #define _ENVIRONMENT_REFLECTION_ON 1
            #define _NORMALMAP 0
            #define _ADDITIONAL_LIGHTS_VERTEX 1

            #include "SceneCommonPass.hlsl"
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
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "CommonMetaPass.hlsl"
            ENDHLSL
        }
    }

    SubShader
    {
        HLSLINCLUDE
            #include "SceneCommonInput.hlsl"
        ENDHLSL
        
        LOD 100
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite] Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_fog
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //#pragma multi_compile _ _SHADOWS_SOFT
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag

            #define _SPECULAR_ON 0
            #define _ENVIRONMENT_REFLECTION_ON 0
            #define _RIM 0
            #define _SSS 0
            #define _NORMALMAP 0

            #include "SceneCommonPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "CommonMetaPass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "SceneCommonGUI"
}
