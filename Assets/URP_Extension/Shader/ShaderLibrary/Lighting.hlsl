#ifndef BIOUM_LIGHTING_INCLUDED
#define BIOUM_LIGHTING_INCLUDED

#include "Common.hlsl"
#include "Light.hlsl"
#include "BRDF.hlsl"
#include "GI.hlsl"
#include "Fog.hlsl"







half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingPBR(BRDF brdf, Surface surface, GI gi)
{
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular); 

    Light light = GetMainLight();

    half3 lambert = LightingLambert(light.color, light.direction, surface.normal);
    color += lambert * DirectBRDF(surface, brdf, light);


    
    //half3 lambert = LightingLambert(light.color, light.direction, surface.normal);

    //half3 color = lambert * brdf.diffuse + SH;
    return color;
}

#endif  //BIOUM_LIGHTING_INCLUDED