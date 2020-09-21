#ifndef BIOUM_LIGHTING_INCLUDED
#define BIOUM_LIGHTING_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Light.hlsl"
#include "BRDF.hlsl"
#include "GI.hlsl"

struct FSphericalGausian
{
    half3 Axis;
    half3 Sharpness;
    //half3 Amplitude;
};

half3 DotCosineLobe(FSphericalGausian SG, half3 normalWS)
{
    half muDotN = dot(SG.Axis, normalWS);
    half c0 = 0.36, c1 = 0.25 / c0;

    half3 eml = exp(-SG.Sharpness);
    half3 em2l = eml * eml;
    half3 rl = rcp(SG.Sharpness);

    half3 scale = 1 + 2 * em2l - rl;
    half3 bias = (eml - em2l) * rl - em2l;

    half3 x = sqrt(1 - scale);
    half3 x0 = c0 * muDotN;
    half3 x1 = c1 * x;

    half3 n = x0 + x1;
    half3 y = (abs(x0) <= x1) ? n * n / x : saturate(muDotN);

    return scale * y + bias;
}

FSphericalGausian MakeNormalizedSG(half3 lightDirWS, half3 sharpness)
{
    FSphericalGausian SG;
    SG.Axis = lightDirWS;
    SG.Sharpness = sharpness;
    //SG.Amplitude = SG.Sharpness / (TWO_PI * (1 - exp(-2 * SG.Sharpness)));
    return SG;
}

half3 SGDiffuseLighting(half3 normalWS, half3 lightDirWS, half3 SSSColor)
{
    FSphericalGausian rgbKernel = MakeNormalizedSG(lightDirWS, rcp(max(SSSColor, 0.001)));
    half3 diffuse = DotCosineLobe(rgbKernel, normalWS);

    //filmic tonemapping
    half3 x = max(0, (diffuse - 0.004));
    diffuse = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
    
    return diffuse;
}

half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 IncomingLight(Surface surface, Light light)
{
    half3 atten = light.shadowAttenuation * light.distanceAttenuation;
    half3 color = 1;
#if _SSS
    half3 SG = SGDiffuseLighting(surface.normal, light.direction, surface.SSSColor);
    half NdotL = saturate(dot(surface.normal, light.direction));
    atten = lerp(SG, atten, NdotL);
    color = light.color;
#else
    color = Lambert(light.color, light.direction, surface.normal);
#endif
    return color * atten;
}

half SpecularStrength(Surface surface, BRDF brdf, Light light)
{
    half3 h = SafeNormalize(light.direction + surface.viewDirection);
    half nh2 = Square(saturate(dot(surface.normal, h)));
    half lh2 = Square(saturate(dot(light.direction, h)));
    half d2 = Square(nh2 * brdf.roughness2MinusOne + 1.00001);
    half spec = brdf.roughness2 / (d2 * max(0.1, lh2) * brdf.normalizationTerm);
    spec = min(100, spec);
    return spec;
}

half3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
    half3 specular = brdf.diffuse;

#if _SPECULAR_ON
    specular += SpecularStrength(surface, brdf, light) * brdf.specular;
#endif

    half3 radiance = IncomingLight(surface, light);

    return specular * radiance;
}


half3 IndirectBRDF(Surface surface, BRDF brdf, half3 diffuse, half3 specular)
{
    float fresnelStrength = Pow4(1.0 - saturate(dot(surface.normal, surface.viewDirection)));
    fresnelStrength *= surface.fresnelStrength;

    half3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
    reflection /= brdf.roughness2 + 1.0;

    return diffuse * brdf.diffuse + reflection;
}


half3 BackRim(half3 lightDirWS, half3 normalWS, half3 viewDirWS, half4 rimColor)
{
    half3 backLightDir = lightDirWS * half3(-1, 0.25, -1);
    half NdotV = saturate(dot(normalWS, viewDirWS));
    half NdotBL = dot(normalWS, backLightDir) * 0.5 + 0.5;
    half2 range = PositivePow(half2(1 - NdotV, NdotBL), rimColor.a);

    return range.yyy * range.xxx * rimColor.rgb;
}



half3 LightingPBR(BRDF brdf, Surface surface, VertexData vertexData, GI gi, half4 rimColor = half4(0,0,0,0))
{
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 

    Light mainLight = GetMainLight(vertexData.shadowCoord, gi.shadowMask);
    color += DirectBRDF(surface, brdf, mainLight);

#if _RIM
    color += BackRim(mainLight.direction, surface.normal, surface.viewDirection, rimColor);
#endif

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += DirectBRDF(surface, brdf, light);
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * brdf.diffuse;
#endif

    return color;
}

half3 LightingLambert(Surface surface, VertexData vertexData, GI gi, half4 rimColor = half4(0,0,0,0))
{
    half3 color = surface.albedo.rgb * gi.diffuse;
    color *= surface.occlusion; 

    Light mainLight = GetMainLight(vertexData.shadowCoord, gi.shadowMask);
    color += IncomingLight(surface, mainLight) * surface.albedo.rgb;

#if _RIM
    color += BackRim(mainLight.direction, surface.normal, surface.viewDirection, rimColor);
#endif

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += IncomingLight(surface, light) * surface.albedo.rgb;
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * surface.albedo.rgb;
#endif

    return color;
}

#endif  //BIOUM_LIGHTING_INCLUDED