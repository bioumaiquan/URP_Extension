Shader "Bioum/Scene/Grass"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [HDR]_WaveColor("颜色", Color) = (0.8,1,0.3,1)
        _TopColor("颜色", Color) = (0.8,1,0.3,1)
        [MainTexture]_BaseMap ("贴图", 2D) = "grey" {}

        _DitherCutoff("Dither范围", Range(0.0, 1.0)) = 0.2
        _Cutoff("透贴强度", Range(0.0, 1.0)) = 0.5

        [Toggle(_SSS)] _sssToggle ("SSS开关", float) = 0
        _SSSColor ("SSS颜色", Color) = (0.7, 0.07, 0.01, 1)

        [Toggle(_WIND)] _WindToggle ("风开关", float) = 0
        _WindScale ("缩放", float) = 0.2
        _WindSpeed ("速度", float) = 0.5
        _WindDirection ("风向", range(0,90)) = 40
        _WindIntensity ("强度", range(0, 1)) = 0.2
        _WindParam ("风参数", vector) = (0.2, 0, 0.2, 0.5)

        [Toggle(_DITHER_CLIP)] _DitherClip ("_DitherClip", float) = 0

        [HideInInspector] _BlendMode ("_BlendMode", float) = 0
        [HideInInspector] _CullMode ("_CullMode", float) = 0
        [HideInInspector] _Cull ("_Cull", float) = 2
    }
    SubShader
    {
        HLSLINCLUDE
            #include "SceneGrassInput.hlsl"
        ENDHLSL
        
        LOD 300
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma shader_feature _ _ALPHATEST_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _ _DITHER_CLIP
            #pragma shader_feature _ _SSS
            #pragma shader_feature _ _WIND
            
            #pragma vertex SimpleLitVert
            #pragma fragment SimpleLitFrag

            #include "SceneGrassPass.hlsl"
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

            #pragma shader_feature _ _ALPHATEST_ON
            #pragma shader_feature _ _DITHER_CLIP
            #pragma shader_feature _ _WIND

            #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }

    
    CustomEditor "SceneGrassGUI"
}
