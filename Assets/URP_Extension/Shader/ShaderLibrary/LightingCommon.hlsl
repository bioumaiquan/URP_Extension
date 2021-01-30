#ifndef BIOUM_LIGHTING_INCLUDED
#define BIOUM_LIGHTING_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "LightingBase.hlsl"



half4 g_BackLightColor;
half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    //return lightColor * NdotL;
    half3 backColor = lerp(0, g_BackLightColor.rgb, g_BackLightColor.a);
    return lerp(backColor, lightColor, NdotL);
}

half3 VertexLighting(Light light, real3 normalWS, float3 positionWS)
{
	real3 color = 0;
	uint vertexLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < vertexLightCount; ++ lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        color += Lambert(light.color, light.direction, normalWS) * light.distanceAttenuation;
    }

	return color;
}

half3 IncomingLight(Surface surface, Light light, bool isMainLight = true)
{
    half3 shadow = light.shadowAttenuation;
    half3 color = 1;
#if _SSS
    UNITY_BRANCH
    if(isMainLight)
    {
        half3 SG = SGDiffuseLighting(surface.normal, light.direction, surface.SSSColor);
        //half NdotL = saturate(dot(surface.normal, light.direction));
        //shadow = lerp(SG, shadow, NdotL);
        shadow = min(SG, shadow);
        color = light.color;
    }
    else
    {
        color = Lambert(light.color, light.direction, surface.normal);
    }
#else
    color = Lambert(light.color, light.direction, surface.normal);
#endif
    half3 backColor = lerp(0, g_BackLightColor.rgb, g_BackLightColor.a);
    shadow = lerp(backColor, shadow, shadow);
    return color * shadow * light.distanceAttenuation;
}


half3 DirectBRDF(Surface surface, BRDF brdf, Light light, bool isMainLight = true)
{
    half3 specular = brdf.diffuse;

#if _SPECULAR_ON
    specular += SpecularStrength(surface, brdf, light) * brdf.specular;
#endif

    half3 radiance = IncomingLight(surface, light, isMainLight);

    return specular * radiance;
}



// final lighting

half3 LightingPBR(BRDF brdf, Surface surface, VertexData vertexData, GI gi, half4 rimColor = half4(0,0,0,0))
{
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord, gi.shadowMask);
    color += DirectBRDF(surface, brdf, mainLight, true);

#if _RIM
    color += RimColor(mainLight.direction, surface.normal, surface.viewDirection, rimColor);
#endif

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += DirectBRDF(surface, brdf, light, false);
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * brdf.diffuse;
#endif

#if _SIMPLE_SSS
    color += SimpleSSS(surface, mainLight.direction, surface.SSSColor.a);
#endif

    return color;
}

half3 LightingLambert(Surface surface, VertexData vertexData, GI gi, half4 rimColor = half4(0,0,0,0))
{
    half3 color = surface.albedo.rgb * gi.diffuse;
    color *= surface.occlusion; 

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord, gi.shadowMask);

    color += IncomingLight(surface, mainLight, true) * surface.albedo.rgb;

#if _RIM
    color += RimColor(mainLight.direction, surface.normal, surface.viewDirection, rimColor);
#endif

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += IncomingLight(surface, light, false) * surface.albedo.rgb;
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * surface.albedo.rgb;
#endif

#if _SIMPLE_SSS
    color += SimpleSSS(surface, mainLight.direction, surface.SSSColor.a);
#endif

    return color;
}


#endif  //BIOUM_LIGHTING_INCLUDED