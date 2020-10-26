Shader "Unlit/SobelFilter"
{
	Properties 
	{
	    [HideInInspector]_MainTex ("Base (RGB)", 2D) = "white" {}
		_Delta ("Line Thickness", Range(0, 4)) = 1
		[Toggle(RAW_OUTLINE)]_Raw ("Outline Only", Float) = 0
		_OutlineFactor ("_OutlineFactor", range(0,1)) = 0.7
		_OutlineColor ("_OutlineColor", color) = (0,0,0,1)
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		
		Pass
		{
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #pragma vertex vert
			#pragma fragment frag
            
            #pragma shader_feature _ RAW_OUTLINE
            
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            half4 _CameraDepthTexture_TexelSize;
            
#ifndef RAW_OUTLINE
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
#endif
            float _Delta;
            int _PosterizationCount;
            half _OutlineFactor;
            half4 _OutlineColor;
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float SampleDepth(float2 uv)
            {
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                return SAMPLE_TEXTURE2D_ARRAY(_CameraDepthTexture, sampler_CameraDepthTexture, uv, unity_StereoEyeIndex).r;
#else
                return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
#endif
            }
            
            float sobel (float2 uv) 
            {
                float2 delta = _CameraDepthTexture_TexelSize.xy * _Delta;
                
                float hr = 0;
                float vt = 0;
                
                hr += SampleDepth(uv + float2(-1.0, -1.0) * delta);
                hr += -SampleDepth(uv + float2( 1.0, -1.0) * delta);
                hr += SampleDepth(uv + float2(-1.0,  0.0) * delta) *  2.0;
                hr += -SampleDepth(uv + float2( 1.0,  0.0) * delta) *  2.0;
                hr += SampleDepth(uv + float2(-1.0,  1.0) * delta);
                hr += -SampleDepth(uv + float2( 1.0,  1.0) * delta);
                
                vt += SampleDepth(uv + float2(-1.0, -1.0) * delta);
                vt += SampleDepth(uv + float2( 0.0, -1.0) * delta) *  2.0;
                vt += SampleDepth(uv + float2( 1.0, -1.0) * delta);
                vt += -SampleDepth(uv + float2(-1.0,  1.0) * delta);
                vt += -SampleDepth(uv + float2( 0.0,  1.0) * delta) * 2.0;
                vt += -SampleDepth(uv + float2( 1.0,  1.0) * delta);
                
                return sqrt(hr * hr + vt * vt);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = input.uv;
                
                return output;
            }
            
            half4 frag (Varyings input) : SV_Target 
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float s = pow(1 - saturate(sobel(input.uv)), 70);
                s = step(_OutlineFactor, s);

#ifdef RAW_OUTLINE
                return half4(s.xxx, 1);
#else
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);    
                col.rgb = lerp(_OutlineColor.rgb * col.rgb, col.rgb, s);            
                return col;
#endif
            }
            	
			ENDHLSL
		}
	} 
}
