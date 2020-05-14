#ifndef BIOUM_BRDF_INCLUDE
#define BIOUM_BRDF_INCLUDE

struct BRDF 
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half fresnel;

    half normalizationTerm;   // roughness * 4.0 + 2.0
    half roughness2MinusOne;  // roughness^2 - 1.0
};

#define MIN_REFLECTIVITY 0.04
half OneMinusReflectivity(half metallic) 
{
	half range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

BRDF GetBRDF(Surface surface)
{
    half oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

    BRDF brdf;
    brdf.diffuse = surface.albedo * oneMinusReflectivity;
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.albedo, surface.metallic);

    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);  // 1 - smoothness
	brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);  // perceptualRoughness^2
	brdf.roughness2 = Square(brdf.roughness);

    brdf.fresnel = saturate(surface.smoothness + 1 - oneMinusReflectivity);

    brdf.normalizationTerm = brdf.roughness * 4.0h + 2.0h;
    brdf.roughness2MinusOne = brdf.roughness2 - 1.0h;

    return brdf;
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
    return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}


half3 IndirectBRDF(Surface surface, BRDF brdf, half3 diffuse, half3 specular)
{
    float fresnelStrength = Pow4(1.0 - saturate(dot(surface.normal, surface.viewDirection)));
    fresnelStrength *= surface.fresnelStrength;

    half3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
    reflection /= brdf.roughness2 + 1.0;

    return diffuse * brdf.diffuse + reflection;
}

#endif