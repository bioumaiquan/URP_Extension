Shader "Bioum/Scene/Unlit"
{
    Properties
    {
        [HDR]_RimColor("边缘光颜色", Color) = (0,0,0,1)
        _RimPower("边缘光范围", range(0.5, 10)) = 4
        [MainColor][HDR]_BaseColor("颜色", Color) = (1,1,1,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "white" {}
        _Cutoff ("透贴强度", range(0,1)) = 0.5
        _Transparent ("透明度", range(0,1)) = 1

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _SrcBlend ("_SrcBlend", float) = 1
        [HideInInspector] _DstBlend ("_DstBlend", float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", float) = 1
        [HideInInspector][Toggle] _TransparentZWrite ("_TransparentZWrite", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE
            #include "SceneUnlitInput.hlsl"
        ENDHLSL

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
            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _RIM
            
            #pragma vertex UnlitVert
            #pragma fragment UnlitFrag

            #include "SceneUnlitPass.hlsl"
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
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On ZTest LEqual
            Cull Off ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //#pragma multi_compile_instancing

            #pragma shader_feature _ _ALPHATEST_ON
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "../Shader/ShaderLibrary/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "SceneUnlitGUI"
}
