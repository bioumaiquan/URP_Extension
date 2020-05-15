Shader "Bioum/Scene/Sky/Texture" 
{
    Properties 
    {
        _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _FogStrength ("Fog", Range(0, 1)) = 1.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        [NoScaleOffset] _Panoramic ("Panoramic", 2D) = "grey" {}
        [NoScaleOffset] _CubeTex ("CubeMap", Cube) = "grey" {}
        [Enum(Cube, 0, Panoramic, 1)] _ImageType("贴图类型", Float) = 0
    }

    SubShader 
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass 
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "../Shader/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "../Shader/ShaderLibrary/Fog.hlsl"

            sampler2D _Panoramic; half4 _Panoramic_HDR;
            samplerCUBE _CubeTex; half4 _CubeTex_HDR;

            half4 _Tint;
            half _Exposure;
            float _Rotation;
            int _Layout;
            half _FogStrength;
            int _ImageType;
            #define UNITY_PI 3.14159

            float2 ToRadialCoords(float3 coords)
            {
                float3 normalizedCoords = normalize(coords);
                float latitude = acos(normalizedCoords.y);
                float longitude = atan2(normalizedCoords.z, normalizedCoords.x);
                float2 sphereCoords = float2(longitude, latitude) * float2(0.5/UNITY_PI, 1.0/UNITY_PI);
                return float2(0.5,1.0) - sphereCoords;
            }

            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }

            struct appdata_t 
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f 
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD4;
                float3 texcoord : TEXCOORD0;
            };

            v2f vert (appdata_t v)
            {
                v2f o;
                
                float3 rotated = RotateAroundYInDegrees(v.vertex.xyz, _Rotation);
                o.positionWS = TransformObjectToWorld(rotated);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.texcoord = v.vertex.xyz;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 tex = 0;
                half3 color = 0;
                if (_ImageType == 0) // CubeMap
                {
                    half3 coord = i.texcoord;
                    tex = texCUBE(_CubeTex, coord);
                    color = DecodeHDREnvironment (tex, _CubeTex_HDR);
                }
                else if (_ImageType == 1) // Panoramic
                {
                    half2 coord =  ToRadialCoords(i.texcoord);
                    coord.x = fmod(coord.x, 1);
                    tex = tex2D(_Panoramic, coord);
                    color = DecodeHDREnvironment (tex, _Panoramic_HDR);
                }
                color *= _Exposure;
                
                // color = lerp(color, Bioum_FogColor.rgb, _FogStrength);

                // half3 lightDir = _DirectionalLightDirections[0].xyz;
                // half3 lightColor = _DirectionalLightColors[0].rgb;
                // half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                // half3 scatteringColor = GetScatteringColor(lightDir, lightColor, viewDirWS);
                // color += scatteringColor;

                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
