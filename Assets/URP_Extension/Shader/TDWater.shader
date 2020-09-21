Shader "Bioum/Scene/TDWater"
{
    Properties
    {
        _AlbedoTex ("Texture", 2D) = "white" {}
        _DistortTex ("Distort Texture", 2D) = "white" {}
        [hdr]_WaterColor ("Color", Color) = (1,1,1,1)
        _UVAni ("UV Ani", vector) = (0,0,0,0)
        _DistortUVAni ("Distort UV Ani", vector) = (0,0,0,0)
        _DistortIntensity ("Distort Intensity", range(0,0.2)) = 0.05
        _TexSacle ("Tex Scale", range(0,2)) = 0.5
        _Transparent ("Transparent", range(0,1)) = 0.7
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector" = "True"}
        Pass
        {
            Cull Back ZWrite Off BlendOp Add
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag

            #pragma shader_feature __ BIOU_FOG_SIMPLE
			#pragma shader_feature __ BIOU_FOG_HEIGHT
			#pragma shader_feature __ BIOU_FOG_SCATTERING
            #pragma multi_compile_instancing
            //#include "Biou_Common.hlsl"
            #include "../Shader/ShaderLibrary/Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _UVAni, _DistortUVAni;
            half _DistortIntensity, _TexSacle, _Transparent;
            half4 _DistortTex_ST, _AlbedoTex_ST;
            half4 _WaterColor;
            CBUFFER_END
            TEXTURE2D(_DistortTex);   SAMPLER(sampler_DistortTex);
            TEXTURE2D(_AlbedoTex);   SAMPLER(sampler_AlbedoTex);

            struct appdata
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float4 tangentOS    : TANGENT;
				float2 texcoord     : TEXCOORD0;
				float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
            struct v2f
            {
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (appdata v)
            {
				v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                half ndotu = dot(normalWS, half3(0,1,0));

                o.uv0.xy = ndotu >= 0.5 ? positionWS.xz : positionWS.xy;
                o.uv0.xy *= _AlbedoTex_ST.xy;
                o.uv0.zw = o.uv0.xy * _TexSacle;
                o.uv0.xy += frac(_UVAni.xy * _Time.y);
                o.uv0.zw += frac(_UVAni.zw * _Time.y);

                o.uv1.xy = TRANSFORM_TEX(v.texcoord, _DistortTex);
                o.uv1.xy += frac(_DistortUVAni.xy * _Time.y);
                o.uv1.zw = v.texcoord;

                //half offset = sin(positionWS.z + _Time.y) * 0.1;
                //positionWS.y += offset;

                o.positionCS = TransformWorldToHClip(positionWS);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(i);

                half4 distort = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv1.xy);
                float2 uv1 = i.uv0.xy + distort.xy * _DistortIntensity;
                float2 uv2 = i.uv0.zw + distort.xy * _DistortIntensity;
                half4 col1 = SAMPLE_TEXTURE2D(_AlbedoTex, sampler_AlbedoTex, uv1);
                half4 col2 = SAMPLE_TEXTURE2D(_AlbedoTex, sampler_AlbedoTex, uv2);
                half3 color = col1.rgb * col2.rgb * _WaterColor.rgb;

                return half4(color, _Transparent);
            }
            ENDHLSL
        }
    }
}
