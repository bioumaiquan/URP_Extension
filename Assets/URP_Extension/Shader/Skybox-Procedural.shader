Shader "Bioum/Scene/Sky/Procedural"
{
    Properties
    {
        [NoScaleOffset]_CloudTex ("Cloud Tex", 2D) = "white" { }
        _CloudDensity ("Cloud Density", range(0.001, 10)) = 0.1
        _CloudSize ("Cloud Size", range(0.001, 2)) = 0.5
        _CloudSpeed ("Cloud Speed", range(0, 0.1)) = 0.01
        [IntRange]_ID ("ID", range(0, 10)) = 0
        [hdr]_CloudColor ("Cloud Color", color) = (1,1,1,1)
        [HideInInspector]_SkyColors0 ("_SkyColors", Color) = (1, 1, 1, 1)
        [HideInInspector]_SkyColors1 ("_SkyColors", Color) = (1, 1, 1, 1)
        [HideInInspector]_SkyColors2 ("_SkyColors", Color) = (1, 1, 1, 1)
        [HideInInspector]_SkyColors3 ("_SkyColors", Color) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
        Cull Off ZWrite Off
        
        Pass
        {
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "../Shader/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "../Shader/ShaderLibrary/Fog.hlsl"
            
            half4 _SkyColors0, _SkyColors1, _SkyColors2, _SkyColors3;
            half3 g_MainLightDir;
            half3 g_MainLightColor;
            sampler2D _CloudTex; half4 _CloudTex_ST;
            half _CloudSize, _CloudDensity, _CloudSpeed;
            half4 _CloudColor;
            
            struct appdata_t
            {
                float4 positionOS: POSITION;
                half3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float4 uv: TEXCOORD0;
                half4 normalWS: TEXCOORD1;
                half3 color : COLOR;
            };
            
            v2f vert(appdata_t v)
            {
                v2f o;
                
                half3 positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(positionWS);
                half3 normalWS = normalize(positionWS);
                normalWS.y = saturate(normalWS.y);
                o.normalWS.xyz = normalWS;
                o.normalWS.w = normalWS.y;// * normalWS.y;
                
                positionWS.y *= 5;
                normalWS = normalize(positionWS);
                //half3 up = half3(0,1,0);
                //half ndotu = dot(up, normalWS);

                o.uv.xy = normalWS.xz * _CloudDensity;
                o.uv.x += _Time.y * _CloudSpeed;
                
                o.uv.zw = normalWS.xz * _CloudDensity * 1.456;
                o.uv.z += _Time.y * _CloudSpeed * 0.23;

                //o.color = warp;
                
                return o;
            }
            
            
            
            half4 frag(v2f i): SV_Target
            {
                half3 normalWS = i.normalWS.xyz;
                half3 lightDirWS = g_MainLightDir;
                
                //sun color
                half dist = length(lightDirWS - normalWS);
                half3 sunColor = _SkyColors0.a / max(0.0001, dist * dist); // _SkyColors0.a : sun intensity
                sunColor *= g_MainLightColor;
                
                //sky color
                // 映射函数 ymax,ymin为目标区间, xmax,xmin为当前区间 x为当前值
                // y = ymin + ((ymax - ymin) * (x - xmin)) / (xmax - xmin)
                half height = normalWS.y;
                half ground = 0;
                half3 d = rcp(half3(_SkyColors1.a - ground, _SkyColors2.a - _SkyColors1.a, _SkyColors3.a - _SkyColors2.a));  //倒数
                half lerp0 = saturate((height - ground) * d.x); // 首先将地面颜色(Xmin)到颜色1(Xmax)的范围映射至0-1
                half lerp1 = saturate((height - _SkyColors1.a) * d.y);  // 颜色1(Xmin)和颜色2(Xmax)的范围映射至0-1
                half lerp2 = saturate((height - _SkyColors2.a) * d.z); // 再将颜色2和颜色3的范围映射至0-1
                half3 smoothLerp = half3(smoothstep(0, 1, half3(lerp0, lerp1, lerp2)));
                half3 skyColor = lerp(_SkyColors0.rgb, _SkyColors1.rgb, smoothLerp.x);
                skyColor = lerp(skyColor, _SkyColors2.rgb, smoothLerp.y);
                skyColor = lerp(skyColor, _SkyColors3.rgb, smoothLerp.z);
                
                //cloud
                half2 offset = normalize(lightDirWS.xz);
                half2 uv00 = i.uv.xy;
                half2 uv01 = i.uv.xy + 0.1 * offset * (1 - lightDirWS.y);
                half cloudTex00 = tex2D(_CloudTex, uv00).r;
                half cloudTex01 = tex2D(_CloudTex, uv01).r;

                half2 uv10 = i.uv.zw;
                half2 uv11 = i.uv.zw + 0.1 * offset * (1 - lightDirWS.y);
                half cloudTex10 = tex2D(_CloudTex, uv10).r;
                half cloudTex11 = tex2D(_CloudTex, uv11).r;

                half cloudMask = max(0, (cloudTex00 + cloudTex10) - _CloudSize);
                half cloudMask2 = max(0, (cloudTex01 + cloudTex11) - _CloudSize);
                half3 cloudColor = cloudMask + saturate(cloudMask - cloudMask2) * g_MainLightColor;

                // half cloudTex1 = tex2D(_CloudTex, i.uv.zw).r;
                // half3 cloudColor = (cloudTex0 + cloudTex1) - _CloudSize;
                cloudColor = max(0, cloudColor) * i.normalWS.w;
                
                half3 color = 0;//pow(lerp0, 2.2);
                //color += cloudColor * _CloudColor.rgb;

                //color = skyColor;
                //color = lerp(skyColor, cloudColor, cloud);
                color = skyColor + cloudColor + sunColor;
                
                return half4(color, 1);
            }
            ENDHLSL
            
        }
    }
}
