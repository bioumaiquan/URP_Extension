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
#define ONEMINUS_MIN_REFLECTIVITY 0.96

half OneMinusReflectivity(half metallic) 
{
    half range = ONEMINUS_MIN_REFLECTIVITY;
    return range - metallic * range;
}

BRDF GetBRDF(Surface surface, inout half alpha)
{
    half oneMinusReflectivity = OneMinusReflectivity(surface.metallic);
    half reflectivity = 1 - oneMinusReflectivity;

    BRDF brdf;
    brdf.diffuse = surface.albedo.rgb * oneMinusReflectivity;

    half lum = max(0.001, Luminance(surface.albedo));
    half3 tint = surface.albedo.rgb/lum;
    half3 minReflectivity = MIN_REFLECTIVITY * LerpWhiteTo(tint, surface.specularTint);
    brdf.specular = lerp(minReflectivity, surface.albedo.rgb, surface.metallic);

    brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);  // 1 - smoothness
    brdf.roughness = PerceptualRoughnessToRoughness(max(0.02, brdf.perceptualRoughness));  // perceptualRoughness^2
    brdf.roughness2 = Square(brdf.roughness);

    brdf.fresnel = saturate(surface.smoothness + reflectivity);

    brdf.normalizationTerm = brdf.roughness * 4.0h + 2.0h;
    brdf.roughness2MinusOne = brdf.roughness2 - 1.0h;

    #if _ALPHAPREMULTIPLY_ON
        brdf.diffuse *= alpha;
        alpha = alpha * oneMinusReflectivity + reflectivity;
    #endif

    return brdf;
}


BRDF GetSimpleBRDF(Surface surface, inout half alpha)
{
    BRDF brdf = (BRDF)0;

    brdf.specular = MIN_REFLECTIVITY;
    brdf.diffuse = surface.albedo.rgb * ONEMINUS_MIN_REFLECTIVITY;
    brdf.perceptualRoughness = 1 - surface.smoothness; 
    brdf.roughness = Square(max(0.05, brdf.perceptualRoughness));  // perceptualRoughness^2
    brdf.roughness2 = Square(brdf.roughness);

    brdf.normalizationTerm = brdf.roughness * 4.0h + 2.0h;
    brdf.roughness2MinusOne = brdf.roughness2 - 1.0h;

    #if _ALPHAPREMULTIPLY_ON
        brdf.diffuse *= alpha;
        alpha = alpha * oneMinusReflectivity + reflectivity;
    #endif

    return brdf;
}



#endif