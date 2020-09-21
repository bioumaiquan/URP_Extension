Shader "Bioum/Effect/Common" 
{
	Properties 
	{
		_MainTex ("Main Tex", 2D) = "white" {}
		_SecondaryTex ("Secondary Tex", 2D) = "white" {}
        [Enum(Multiply,0,Add,1)] _TexBlendMode("Tex Blend Mode", float) = 0
		_MainTexUVAni ("MainTex Ani", Vector) = (0,0,0,0)
		_DistortMap ("Distort Tex", 2D) = "grey" {}
		_SecondaryDistortMap ("Secondary Dissolve Tex", 2D) = "grey" {}
		_MaskMap ("Mask Tex", 2D) = "white" {}
		
		_DistortFactor ("扭曲强度", Range(0,0.5) ) = 0.15
		_DistortUVAni ("Distort Ani", Vector) = (0,0,0,0)
		
		[HDR]_TintColor("Color", Color) = (0.5, 0.5, 0.5, 1)  
        _Cutoff("cutoff", Range(0,1)) = 0.5
		
		_rimPower("Rim Power", Range(0,10)) = 5
		[HDR]_rimColor("rimColor", Color) = (1,1,1,1)  
		
		_DissolveFactor("dissolve factor", Range(0,1.01)) = 0.5
		_DissolveEdge("dissolve Edge", Range(0,1)) = 0.1
		_DissolveSoft("dissolve Soft", Range(0.01, 0.49)) = 0.2
		[HDR]_DissolveEdgeColor("dissolve Edge Color", color) = (1,1,1,1)
		_DissolveMap ("Dissolve Tex", 2D) = "white" {}
		[Enum(Hard,0,Soft,1)]_DissolveMode ("Dissolve Mode", float) = 0
		
		[Toggle(ENABLE_SECONDARYTEX)] _EnableSecondaryTex ("贴图2", Float) = 0
		[Toggle(ENABLE_DISTORT)] _Distort ("扭曲", Float) = 0
		[Toggle(ENABLE_MASK)] _Mask ("遮罩", Float) = 0
		[Toggle(ENABLE_RIM)] _Rim ("Rim", Float) = 0
		[Toggle(ENABLE_DISSOLVE)] _Dissolve ("Dissolve", Float) = 0
		[Toggle(ISPARTICLE)] _IsParticle ("is particle", Float) = 0
		[Toggle(_ALPHATEST_ON)] _AlphaTest_On ("AlphaTest", Float) = 0
		
		[HideInInspector] _BlendMode ("__BlendMode", Float) = 0
		[HideInInspector] _SrcBlend ("__src", Float) = 1
		[HideInInspector] _DstBlend ("__dst", Float) = 10
		[HideInInspector] _CullMode ("__CullMode", Float) = 0
		[HideInInspector] _Cull ("__Cull", Float) = 2
		[HideInInspector] _ZWrite ("__ZWrite", Float) = 0
	}
	SubShader 
	{
		Tags {"IgnoreProjector"="True" "Queue"="Transparent" "RenderType"="Transparent" "PreviewType"="Plane"}
		Pass 
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull [_Cull]
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#pragma target 3.5
			#pragma shader_feature __ ENABLE_SECONDARYTEX
			#pragma shader_feature __ ENABLE_DISTORT
			#pragma shader_feature __ ENABLE_MASK
			#pragma shader_feature __ ENABLE_RIM
			#pragma shader_feature __ ENABLE_DISSOLVE
			#pragma shader_feature __ ISPARTICLE
			#pragma shader_feature __ _ADDITIVESOFT_ON _MULTIPLY_ON _ALPHATEST_ON

			sampler2D _MainTex;
            sampler2D _SecondaryTex;
            sampler2D _DistortMap; 
            sampler2D _SecondaryDistortMap;
            sampler2D _MaskMap;
            sampler2D _DissolveMap;

            CBUFFER_START(UnityPerMaterial)
			half4 _MainTex_ST, _SecondaryTex_ST;
			half4 _MainTexUVAni;
            int _TexBlendMode;
            half _Cutoff;
                    
            half4 _DistortMap_ST;
            half4 _SecondaryDistortMap_ST;
            half4 _DistortUVAni;
            half _DistortFactor;

            half4 _MaskMap_ST;
            half4 _DissolveMap_ST;
            half _DissolveFactor;
            half _DissolveEdge;
            half _DissolveSoft;
            half4 _DissolveEdgeColor;
            int _DissolveMode;

            half4 _rimColor;
			half4 _TintColor;
            CBUFFER_END
			
			struct VertexInput 
			{
				float4 positionOS : POSITION;
				half4 texcoord : TEXCOORD0;
				half4 vertexColor : COLOR;
				half3 normalOS : NORMAL;
				
				half4 CustomData1 : TEXCOORD1; //particle system custom data
			};
			
			struct v2f 
			{
				float4 positionCS : SV_POSITION;
				half4 mainUV : TEXCOORD0;
				#if ENABLE_MASK || ENABLE_DISSOLVE
					half4 maskUV : TEXCOORD1;
				#endif
				#if ENABLE_DISTORT
					half4 distortUV : TEXCOORD6;
				#endif
				#if ENABLE_RIM
					half3 normalWS :TEXCOORD2;
					half3 viewDirWS :TEXCOORD3;
				#endif
				half4 vColor : COLOR;
				half4 CustomData1 : TEXCOORD5;
			};
			
			v2f vert (VertexInput v) 
			{
				v2f o = (v2f)0;
				
                float4 positionWS = mul(UNITY_MATRIX_M, v.positionOS);
				o.positionCS = mul(UNITY_MATRIX_VP, positionWS);
				
				#if ISPARTICLE
					o.CustomData1 = half4(v.texcoord.zw, v.CustomData1.xy);
				#else
					o.CustomData1 = half4(1,1,1,1);
				#endif
				
                #if !ENABLE_SECONDARYTEX
                    o.mainUV.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw * o.CustomData1.z;
                    o.mainUV.xy += frac(half2(_MainTexUVAni.xy * _Time.y));
				#elif ENABLE_SECONDARYTEX
					o.mainUV = v.texcoord.xyxy * half4(_MainTex_ST.xy, _SecondaryTex_ST.xy);
                    o.mainUV += half4(_MainTex_ST.zw, _SecondaryTex_ST.zw) * o.CustomData1.z;
					o.mainUV += frac(half4(_MainTexUVAni * _Time.y));
				#endif
				
				#if ENABLE_DISTORT
                    o.distortUV = v.texcoord.xyxy * half4(_DistortMap_ST.xy, _SecondaryDistortMap_ST.xy);
                    o.distortUV += frac(half4(_DistortUVAni * _Time.y));
				#endif
				
				#if ENABLE_MASK || ENABLE_DISSOLVE
                    o.maskUV = v.texcoord.xyxy * half4(_MaskMap_ST.xy, _DissolveMap_ST.xy);
                    o.maskUV += half4(_MaskMap_ST.zw, _DissolveMap_ST.zw);
				#endif
				
				#if ENABLE_RIM
					o.normalWS = TransformObjectToWorldNormal(v.normalOS);
					o.viewDirWS = _WorldSpaceCameraPos.xyz - positionWS.xyz;
				#endif
				
				o.vColor = v.vertexColor;
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target 
			{
				half4 _MainTexColor;
				half4 _SecondaryTexColor;
				#if !ENABLE_DISTORT
					_MainTexColor = tex2D(_MainTex, i.mainUV.xy);
					#if ENABLE_SECONDARYTEX
						_SecondaryTexColor = tex2D(_SecondaryTex, i.mainUV.zw);
						_MainTexColor = _TexBlendMode == 0 ? _MainTexColor * _SecondaryTexColor : _MainTexColor + _SecondaryTexColor;
					#endif
				#else
					half _DistortTex_var = tex2D(_DistortMap, i.distortUV.xy).r - 0.5;
					half _DistortTex2_var = tex2D(_SecondaryDistortMap, i.distortUV.zw).r - 0.5;
					half distort = _DistortTex_var * _DistortTex2_var * _DistortFactor * i.CustomData1.w;
					half4 texUV = i.mainUV + distort;
					_MainTexColor = tex2D(_MainTex, texUV.xy);
					#if ENABLE_SECONDARYTEX
						_SecondaryTexColor = tex2D(_SecondaryTex, texUV.zw);
						_MainTexColor = _TexBlendMode == 0 ? _MainTexColor * _SecondaryTexColor : _MainTexColor + _SecondaryTexColor;
					#endif
				#endif
				
				#if ENABLE_DISSOLVE
					half ClipTex;
					#if !ENABLE_DISTORT
						ClipTex = tex2D(_DissolveMap, i.maskUV.zw).r;
					#else
						half2 dissolveUV = i.maskUV.zw + distort;
						ClipTex = tex2D(_DissolveMap, dissolveUV).r;
					#endif

                    half ClipAera, ClipAeraEdge;
                    half2 ClipAeraAndEdge;

                    UNITY_BRANCH
                    if (_DissolveMode == 0)
                    {
                        ClipAera = step(0, ClipTex - _DissolveFactor * i.CustomData1.x);
                        ClipAeraEdge = step(0, ClipTex - (_DissolveFactor + _DissolveEdge * i.CustomData1.y) * i.CustomData1.x);
                        ClipAeraAndEdge = half2(ClipAera, ClipAeraEdge);
                    }
                    else
                    {
                        half2 f = half2(_DissolveFactor, _DissolveEdge) * i.CustomData1.xy;
                        half2 clipFac = half2(f.x * 2 - 1, f.y);
                        ClipAera = ClipTex - clipFac.x;
                        ClipAeraEdge = ClipAera - clipFac.y;
                        ClipAeraAndEdge = smoothstep(0.5 - _DissolveSoft, 0.5 + _DissolveSoft, half2(ClipAera, ClipAeraEdge));
                    }

				#endif
				
				half3 colorFactor = _MainTexColor.rgb * _TintColor.rgb * i.vColor.rgb;
				half alphaFactor = _MainTexColor.a * _TintColor.a * i.vColor.a;

				#if ENABLE_DISSOLVE
					colorFactor = lerp(_DissolveEdgeColor.rgb * colorFactor, colorFactor, ClipAeraAndEdge.y);
                    alphaFactor *= ClipAeraAndEdge.x;
				#endif
				
				
				#if	_ALPHATEST_ON
					clip(alphaFactor - _Cutoff);
				#endif
				
				half4 col;
				col.rgb = colorFactor;
				col.a = alphaFactor;
				
				#if ENABLE_MASK
					half4 masktex = tex2D(_MaskMap, i.maskUV.xy);
					half mask = min(masktex.r, masktex.a);
					col.a *= mask;
				#endif

				#if ENABLE_RIM
                    half3 normalWS = normalize(i.normalWS);
                    half3 viewDirWS = normalize(i.viewDirWS);
					half rim = 1 - abs(dot(normalWS, viewDirWS));
					rim = PositivePow(rim, _rimColor.a);
					half3 rimColor = rim * _rimColor.rgb;
					col.rgb += rimColor;
				#endif
				
				#if _ADDITIVESOFT_ON
					col.rgb *= col.a;
				#endif
				
				#if _MULTIPLY_ON
					col = lerp(half4(0.5,0.5,0.5,0.5), col, col.a);
				#endif
				
				return col;
			}
			ENDHLSL
		}
	}
	CustomEditor "BioumEffectCommonShaderGUI"
}
