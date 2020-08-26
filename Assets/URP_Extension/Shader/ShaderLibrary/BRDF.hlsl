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
    half clearCoat;

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

    half lum = max(0.01, Luminance(surface.albedo));
    half3 tint = surface.albedo/lum;
    half3 minReflectivity = surface.specularStrength * 0.08 * lerp(1, tint, surface.specularTint);
    brdf.specular = lerp(minReflectivity, surface.albedo, surface.metallic);

    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);  // 1 - smoothness
    brdf.roughness = PerceptualRoughnessToRoughness(max(0.02, brdf.perceptualRoughness));  // perceptualRoughness^2
    brdf.roughness2 = Square(brdf.roughness);

    brdf.fresnel = saturate(surface.smoothness + 1 - oneMinusReflectivity);

    brdf.normalizationTerm = brdf.roughness * 4.0h + 2.0h;
    brdf.roughness2MinusOne = brdf.roughness2 - 1.0h;

    brdf.clearCoat = surface.clearCoat * 0.25;

    return brdf;
}



#endif