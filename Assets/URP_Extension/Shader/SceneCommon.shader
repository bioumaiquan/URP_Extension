Shader "Bioum/Scene/Common"
{
    Properties
    {
        _BaseMap ("Main Tex", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            //Blend [_SrcBlend] [_DstBlend]
            //ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_instancing
            #pragma vertex CommonLitVert
            #pragma fragment CommonLitFrag
            #include "SceneCommonPass.hlsl"

            ENDHLSL
        }
    }
}
