#ifndef BIOUM_SURFACE_UNCLUDE
#define BIOUM_SURFACE_UNCLUDE

struct Surface
{
    half4 albedo;

    half  metallic;
    half3 viewDirection;

    half  smoothness;
    float3 position;

    half  occlusion;
    half3 normal;

    half fresnelStrength;
    half3 SSSColor;

    half  specularTint;
};

struct VertexData
{
    float4 shadowCoord;
    half3 lighting;
    half3 color;
};

#endif