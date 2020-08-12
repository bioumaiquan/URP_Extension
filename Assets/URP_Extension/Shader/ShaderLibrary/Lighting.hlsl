#ifndef BIOUM_LIGHTING_INCLUDED
#define BIOUM_LIGHTING_INCLUDED

#include "Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "BRDF.hlsl"
#include "GI.hlsl"

struct FSphericalGausian
{
    half3 Axis;
    half Sharpness;
    half Amplitude;
};

half DotCosineLobe(FSphericalGausian SG, half3 normalWS)
{
    half muDotN = dot(SG.Axis, normalWS);
    half c0 = 0.36, c1 = 0.25 / c0;

    half eml = exp(-SG.Sharpness);
    half em2l = eml * eml;
    half rl = rcp(SG.Sharpness);

    half scale = 1 + 2 * em2l - rl;
    half bias = (eml - em2l) * rl - em2l;

    half x = sqrt(1 - scale);
    half x0 = c0 * muDotN;
    half x1 = c1 * x;

    half n = x0 + x1;
    half y = (abs(x0) <= x1) ? n * n / x : saturate(muDotN);

    return scale * y + bias;
}

FSphericalGausian MakeNormalizedSG(half3 lightDirWS, half sharpness)
{
    FSphericalGausian SG;
    SG.Axis = lightDirWS;
    SG.Sharpness = sharpness;
    SG.Amplitude = SG.Sharpness / (TWO_PI * (1 - exp(-2 * SG.Sharpness)));
    return SG;
}

half3 SGDiffuseLighting(half3 normalWS, half3 lightDirWS, half3 SSSColor)
{
    FSphericalGausian redKernel = MakeNormalizedSG(lightDirWS, 1 / max(SSSColor.r, 0.001));
    FSphericalGausian greenKernel = MakeNormalizedSG(lightDirWS, 1 / max(SSSColor.g, 0.001));
    FSphericalGausian blueKernel = MakeNormalizedSG(lightDirWS, 1 / max(SSSColor.b, 0.001));
    half3 diffuse = half3(DotCosineLobe(redKernel, normalWS), DotCosineLobe(greenKernel, normalWS), DotCosineLobe(blueKernel, normalWS));

    //filmic tonemapping
    if(_SSSToneMapping)
    {
        half3 x = max(0, (diffuse - 0.004));
        diffuse = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
    }
    return diffuse;
}

half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 IncomingLight(Surface surface, half3 lightColor, half3 lightDir)
{
#if defined(_SSS)
    half3 SG = SGDiffuseLighting(surface.SSSNormal, lightDir, surface.SSSColor);
    return lightColor * SG;
#else
    return Lambert(lightColor, lightDir, surface.normal);
#endif
}

half SpecularStrength(Surface surface, BRDF brdf, Light light)
{
    half3 h = SafeNormalize(light.direction + surface.viewDirection);
    half nh2 = Square(saturate(dot(surface.normal, h)));
    half lh2 = Square(saturate(dot(light.direction, h)));
    half d2 = Square(nh2 * brdf.roughness2MinusOne + 1.00001);
    return brdf.roughness2 / (d2 * max(0.1, lh2) * brdf.normalizationTerm);
}

half3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
    half3 specular = SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
    half3 radiance = IncomingLight(surface, light.color, light.direction) * light.shadowAttenuation * light.distanceAttenuation;

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


//clear coat






half3 LightingPBR(BRDF brdf, Surface surface, VertexData vertexData, GI gi)
{
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 

    half4 shadowCoord = TransformWorldToShadowCoord(surface.position);
    Light mainLight = GetMainLight(shadowCoord);
    color += DirectBRDF(surface, brdf, mainLight);

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

#endif  //BIOUM_LIGHTING_INCLUDED