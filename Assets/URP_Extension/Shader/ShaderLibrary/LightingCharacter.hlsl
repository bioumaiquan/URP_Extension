#ifndef BIOUM_LIGHTING_CHARACTER_INCLUDED
#define BIOUM_LIGHTING_CHARACTER_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "LightingBase.hlsl"

struct CharacterParam
{
    half3 lightColorBack;
    half lightIntensity;
    half smoothDiff;

    half3 rimColorFront;
    half3 rimColorBack;
    half2 rimOffset;
    half rimPower;
    half rimSmooth;
};

struct HairParam
{
    half2 shift;
    half2 smoothness;
    half2 specIntensity;
    half3 tangent;
};


half3 Lambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
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
    //half3 backColor = lerp(0, g_BackLightColor.rgb, g_BackLightColor.a);
    //shadow = lerp(backColor, shadow, shadow);
    return color * shadow * light.distanceAttenuation;
}

half3 IncomingLightTone(CharacterParam characterParam, Surface surface, Light light, bool isMainLight = true)
{
    half3 atten = light.shadowAttenuation * light.distanceAttenuation;
    half3 color = light.color * characterParam.lightIntensity;
#if _SSS
    UNITY_BRANCH
    if(isMainLight)
    {
        half3 SG = SGDiffuseLighting(surface.normal, light.direction, surface.SSSColor);
        half3 smoothSG = smoothstep(0, characterParam.smoothDiff, SG);
        atten *= smoothSG;
    }
    else
    {
        half NdotL = dot(surface.normal, light.direction);
        half smoothNdotL = smoothstep(0, characterParam.smoothDiff, NdotL);
        atten *= smoothNdotL;
    }
#else
    half NdotL = dot(surface.normal, light.direction);
    half smoothNdotL = smoothstep(0, characterParam.smoothDiff, NdotL);
    atten *= smoothNdotL;
#endif

    UNITY_BRANCH
    if(isMainLight)
    {
        characterParam.lightColorBack = LinearToSRGB(characterParam.lightColorBack);
        characterParam.lightColorBack = characterParam.lightColorBack * 2 - 1;
        characterParam.lightColorBack *= saturate(characterParam.lightIntensity);
        return lerp(characterParam.lightColorBack, color, atten);
    }
    else
    {
        return color * atten;
    }

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
half3 DirectBRDFTone(CharacterParam characterParam, Surface surface, BRDF brdf, Light light, bool isMainLight = true)
{
    half3 specular = brdf.diffuse;

#if _SPECULAR_ON
    specular += SpecularStrength(surface, brdf, light) * brdf.specular;
#endif

    half3 radiance = IncomingLightTone(characterParam, surface, light, isMainLight);

    return specular * radiance;
}


half3 ToneRim(CharacterParam characterParam, half3 fragColor, half3 normalVS, half4 viewDirVS, half occlusion) // viewDirVS.w : lightDirVS.x
{
    half2 offset = half2(-viewDirVS.w, viewDirVS.w) * characterParam.rimOffset;
    half3 frontView = viewDirVS.xyz + half3(offset.x, 0, 0);
    half3 backView = viewDirVS.xyz + half3(offset.y, 0, 0);
    half NdotFV = max(0, dot(normalVS, frontView));
    half NdotBV = max(0, dot(normalVS, backView));

    half NdotU = saturate(normalVS.y * 0.7 + 0.3);  // normalVS.y = dot(normalVS, (0, 1, 0))
    half2 rim = PositivePow(1 - half2(NdotFV, NdotBV), characterParam.rimPower);
    rim = smoothstep(0.5 - characterParam.rimSmooth, 0.5 + characterParam.rimSmooth, rim);
    rim *= half2(NdotU, 1 - NdotU) * occlusion;

    half3 rimFColor = rim.x * characterParam.rimColorFront.rgb;
    fragColor += rimFColor;

    fragColor = lerp(fragColor, fragColor * characterParam.rimColorBack, rim.y);

    return fragColor;
}



//hair
half3 ShiftT(half3 tangent, half3 normal, half shift)
{
	return tangent + normal * shift;
}
half KajiyaKaySpec(half3 tangent, half3 viewDirWS, half3 lightDirWS, half smoothness)
{
	half3 halfDir = normalize(lightDirWS + viewDirWS);
	half tdoth = dot(tangent, halfDir);
	half sinTH = sqrt(max(0, 1 - tdoth * tdoth));
	half dirAtten = smoothstep(-1, 0, tdoth);

	half roughness = Pow4(1 - smoothness);
	half power = rcp(max(0.001, roughness));
    half intensity = smoothness * smoothness;

	return dirAtten * PositivePow(sinTH, power) * intensity;
}
half3 DirectHairSpecular(Light light, half3 diffuse, Surface surface, half3 tangent, half2 shift, 
                        half2 intensity, half subSmoothness, bool isMainLight = true)
{
    half3 lambert = IncomingLight(surface, light, isMainLight);
    half3 shiftTangent0 = ShiftT(tangent, surface.normal, shift.x);
    half3 spec0 = KajiyaKaySpec(shiftTangent0, surface.viewDirection, light.direction, surface.smoothness) * intensity.x;
    half3 spec1 = 0;
#if _DOUBLE_SPECULAR
    half3 shiftTangent1 = ShiftT(tangent, surface.normal, shift.y);
    spec1 = KajiyaKaySpec(shiftTangent1, surface.viewDirection, light.direction, subSmoothness) * intensity.y;
#endif

    half3 specColor = lerp(1, surface.albedo.rgb, surface.metallic);
    specColor *= spec0 + spec1;
    return lambert * (diffuse + specColor);
}
half3 DirectHairSpecularTone(CharacterParam characterParam, Light light, half3 diffuse, Surface surface, HairParam hairParam, bool isMainLight = true)
{
    half3 lambert = IncomingLightTone(characterParam, surface, light, isMainLight);
    half3 shiftTangent0 = ShiftT(hairParam.tangent, surface.normal, hairParam.shift.x);
    half3 spec0 = KajiyaKaySpec(shiftTangent0, surface.viewDirection, light.direction, hairParam.smoothness.x) * hairParam.specIntensity.x;
    half3 spec1 = 0;
#if _DOUBLE_SPECULAR
    half3 shiftTangent1 = ShiftT(hairParam.tangent, surface.normal, hairParam.shift.y);
    spec1 = KajiyaKaySpec(shiftTangent1, surface.viewDirection, light.direction, hairParam.smoothness.y) * hairParam.specIntensity.y;
#endif

    half3 specColor = lerp(1, surface.albedo.rgb, surface.metallic);
    specColor *= spec0 + spec1;
    return lambert * (diffuse + specColor);
}
//hair


// final lighting


half3 LightingCharacterCommon(BRDF brdf, Surface surface, VertexData vertexData, GI gi, half4 rimColor = half4(0,0,0,0))
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

    return color;
}

half3 LightingSkin(BRDF brdf, Surface surface, VertexData vertexData, GI gi, half4 rimColor)
{
    half3 color = brdf.diffuse * gi.diffuse * surface.occlusion;

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord);
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

    return color;
}

half3 LightingHair(BRDF brdf, Surface surface, GI gi, VertexData vertexData, 
                    half3 tangent, half2 shift, half2 intensity, half subSmoothness, half4 rimColor)
{
    gi.specular = lerp(gi.specular * 0.1, gi.specular, surface.metallic);
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion;

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord);
    color += DirectHairSpecular(mainLight, brdf.diffuse, surface, tangent, shift, intensity, subSmoothness, true);

#if _RIM
    color += RimColor(mainLight.direction, surface.normal, surface.viewDirection, rimColor);
#endif

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += DirectHairSpecular(light, brdf.diffuse, surface, tangent, shift, intensity, subSmoothness, false);
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * surface.albedo.rgb;
#endif
    
    return color;
}





/// tone lighting
half3 LightingCharacterTone(CharacterParam characterParam, BRDF brdf, Surface surface, VertexData vertexData, GI gi)
{
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion; 

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord);
    color += DirectBRDFTone(characterParam, surface, brdf, mainLight, true);
    color = max(0.001, color);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += DirectBRDFTone(characterParam, surface, brdf, light, false);
        color = max(0.001, color);
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * brdf.diffuse;
#endif

    return color;
}
half3 LightingCharacterHairTone(CharacterParam characterParam, BRDF brdf, Surface surface, GI gi, VertexData vertexData, HairParam hairParam)
{
    gi.specular = lerp(gi.specular * 0.1, gi.specular, surface.metallic);
    half3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    color *= surface.occlusion;

    Light mainLight = GetMainLight(surface.position, vertexData.shadowCoord);
    color += DirectHairSpecularTone(characterParam, mainLight, brdf.diffuse, surface, hairParam, true);
    color = max(0.001, color);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, surface.position);
        color += DirectHairSpecularTone(characterParam, light, brdf.diffuse, surface, hairParam, false);
        color = max(0.001, color);
    }
#elif _ADDITIONAL_LIGHTS_VERTEX
    color += vertexData.lighting * surface.albedo.rgb;
#endif
    
    return color;
}
// tone lighting

#endif  //BIOUM_LIGHTING_CHARACTER_INCLUDED