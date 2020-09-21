#ifndef BIOUM_SURFACE_UNCLUDE
#define BIOUM_SURFACE_UNCLUDE

struct Surface
{
    half4 albedo;

    half  metallic;
    half3 viewDirection;

    half  smoothness;
    half3 position;

    half  occlusion;
    half3 normal;

    half fresnelStrength;
    half3 SSSColor;

    half  specularTint;
};

struct VertexData
{
    half4 shadowCoord;
    half3 lighting;
    half3 color;
};

#endif