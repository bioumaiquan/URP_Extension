Shader "Bioum/Scene/FakeRoom"
{
    Properties
    {
        [NoScaleOffset]_WindowTex ("Window Texture", 2D) = "black" {}
        [NoScaleOffset]_RoomTex ("Room Texture", CUBE) = ""{}
        _RoomDepth ("Room Depth", Range(0.01, 1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Back

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../Shader/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD1;
                float3 viewDirOS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
            };

            sampler2D _WindowTex;
            samplerCUBE _RoomTex;
            float4 _RoomTex_ST;
            half _RoomDepth;
            
            bool IntersectRayAABB(float3 rayOrigin, float3 rayDirection,
            float3 boxMin,    float3 boxMax,
            float  tMin,       float tMax,
            out float  tEntr,  out float tExit)
            {
                // Could be precomputed. Clamp to avoid INF. clamp() is a single ALU on GCN.
                // rcp(FLT_EPS) = 16,777,216, which is large enough for our purposes,
                // yet doesn't cause a lot of numerical issues associated with FLT_MAX.
                float3 rayDirInv = clamp(rcp(rayDirection), -rcp(FLT_EPS), rcp(FLT_EPS));
                
                // Perform ray-slab intersection (component-wise).
                float3 t0 = boxMin * rayDirInv - (rayOrigin * rayDirInv);
                float3 t1 = boxMax * rayDirInv - (rayOrigin * rayDirInv);
                
                // Find the closest/farthest distance (component-wise).
                float3 tSlabEntr = min(t0, t1);
                float3 tSlabExit = max(t0, t1);
                
                // Find the farthest entry and the nearest exit.
                tEntr = Max3(tSlabEntr.x, tSlabEntr.y, tSlabEntr.z);
                tExit = Min3(tSlabExit.x, tSlabExit.y, tSlabExit.z);
                
                // Clamp to the range.
                tEntr = max(tEntr, tMin);
                tExit = min(tExit, tMax);
                
                return tEntr < tExit;
            }
            
            v2f vert (appdata input)
            {
                v2f o;
                half3 positionWS = TransformObjectToWorld(input.positionOS);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.uv = input.uv;
                o.positionOS = input.positionOS;
                half3 cameraPositionOS = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
                o.viewDirOS = cameraPositionOS - input.positionOS;
                o.normalOS = input.normalOS;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                
                half4 windowColor = tex2D(_WindowTex, i.uv);
                float3 viewDirOS = normalize(i.viewDirOS);
                float3 normalOS = i.normalOS;
                float radius = 0.5, posEntr, posExit;
                float bias = 2 * radius * (1 - _RoomDepth);
                
                float3 boxMin = (float3)(-radius) + lerp((float3)0, bias * normalOS, Max3(normalOS.x, normalOS.y, normalOS.z));
                float3 boxMax = (float3)(radius) + lerp(bias * normalOS, (float3)0, Max3(normalOS.x, normalOS.y, normalOS.z));
                
                IntersectRayAABB(i.positionOS, -viewDirOS, boxMin, boxMax, 1, 2, posEntr, posExit);
                float3 sampleDir = i.positionOS - posExit * viewDirOS;
                sampleDir -= bias * normalOS;

                half4 col = texCUBElod(_RoomTex, float4(sampleDir, 0));
                col.rgb = lerp(col.rgb, windowColor.rgb, windowColor.a);
                return col;
            }

            ENDHLSL
        }
    }
}
