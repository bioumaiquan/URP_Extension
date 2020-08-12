#ifndef BIOUM_SURFACE_UNCLUDE
#define BIOUM_SURFACE_UNCLUDE

struct Surface
{
    half3 albedo;
    half3 specular;
    half3 viewDirection;
    half3 position;
    half  metallic;
    half  smoothness;
    half3 normal;
    half  occlusion;
    half  alpha;
    half  specularStrength;
    half  specularTint;
    half  clearCoat;
    half3  clearCoatNormal;
    half fresnelStrength;
    half3 SSSColor;
    half3 SSSNormal;
};

struct VertexData
{
    half3 lighting;
    half3 color;
};

#endif