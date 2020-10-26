Shader "Bioum/Scene/Cloud"
{
    Properties
    {
        [MainColor]_BaseColor("颜色", Color) = (1,1,1,1)
        [HDR]_EmiColor("自发光颜色", Color) = (0,0,0,1)

        [HDR]_RimColor ("边缘光颜色", Color) = (0,0,0,1)
        _RimPower ("边缘光范围", range(1, 20)) = 4

    }

    HLSLINCLUDE
        #include "../Shader/ShaderLibrary/Common.hlsl"
        #include "../Shader/ShaderLibrary/Surface.hlsl"
        #include "../Shader/ShaderLibrary/Noise.hlsl"

        CBUFFER_START(UnityPerMaterial)
        half4 _BaseColor;
        half4 _EmiColor;
        half4 _RimColor;
        half _RimPower;
        CBUFFER_END
    ENDHLSL

    SubShader
    {  
        LOD 200
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_fog
            #define _RIM 1
            #define _NOISE 1
            
            #pragma vertex CloudLitVert
            #pragma fragment CloudLitFrag

            #include "SceneCloudPass.hlsl"
            ENDHLSL
        }
        // Pass
        // {
        //     Name "DepthOnly"
        //     Tags{"LightMode" = "DepthOnly"}

        //     ZWrite On
        //     ColorMask 0
        //     Cull[_Cull]

        //     HLSLPROGRAM
        //     #pragma prefer_hlslcc gles
        //     #pragma exclude_renderers d3d11_9x
        //     #pragma target 3.5

        //     #pragma vertex DepthOnlyVertex
        //     #pragma fragment DepthOnlyFragment

        //     #pragma shader_feature _ _ALPHATEST_ON
        //     #pragma shader_feature _ _WIND

        //     #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
        //     ENDHLSL
        // }
    }

    SubShader
    {  
        LOD 100
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_fog
            #define _RIM 0
            #define _NOISE 0
            
            #pragma vertex CloudLitVert
            #pragma fragment CloudLitFrag

            #include "SceneCloudPass.hlsl"
            ENDHLSL
        }
        // Pass
        // {
        //     Name "DepthOnly"
        //     Tags{"LightMode" = "DepthOnly"}

        //     ZWrite On
        //     ColorMask 0
        //     Cull[_Cull]

        //     HLSLPROGRAM
        //     #pragma prefer_hlslcc gles
        //     #pragma exclude_renderers d3d11_9x
        //     #pragma target 3.5

        //     #pragma vertex DepthOnlyVertex
        //     #pragma fragment DepthOnlyFragment

        //     #pragma shader_feature _ _ALPHATEST_ON
        //     #pragma shader_feature _ _WIND

        //     #include "../Shader/ShaderLibrary/DepthOnlyPass.hlsl"
        //     ENDHLSL
        // }
    }

    CustomEditor "SceneCloudGUI"
}
