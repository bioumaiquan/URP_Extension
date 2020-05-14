#ifndef BIOUM_GI_INCLUDE
#define BIOUM_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"




// Samples SH L0, L1 and L2 terms
half3 SampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
}


// Sample baked lightmap. Non-Direction and Directional if available.
// Realtime GI is not supported.
half3 SampleLightmap(float2 lightmapUV, half3 normalWS)
{
#ifdef UNITY_LIGHTMAP_FULL_HDR
    bool encodedLightmap = false;
#else
    bool encodedLightmap = true;
#endif

    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);

    // The shader library sample lightmap functions transform the lightmap uv coords to apply bias and scale.
    // However, universal pipeline already transformed those coords in vertex. We pass half4(1, 1, 0, 0) and
    // the compiler will optimize the transform away.
    half4 transformCoords = half4(1, 1, 0, 0);

#ifdef DIRLIGHTMAP_COMBINED
    return SampleDirectionalLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap),
        TEXTURE2D_ARGS(unity_LightmapInd, samplerunity_Lightmap),
        lightmapUV, transformCoords, normalWS, encodedLightmap, decodeInstructions);
#elif defined(LIGHTMAP_ON)
    return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
#else
    return half3(0.0, 0.0, 0.0);
#endif
}



struct GI 
{
	half3 diffuse;
	half3 specular;
};

GI GetGI (Surface surfaceWS, BRDF brdf) 
{
	GI gi;
    gi.diffuse = SampleSH(surfaceWS);
    gi.specular = 0;
	// gi.diffuse = SampleLightMap(lightMapUV) + SampleSH(surfaceWS);
	// gi.specular = SampleEnvironment(surfaceWS, brdf);

	// gi.shadowMask.always = false;
	// gi.shadowMask.distance = false;
	// gi.shadowMask.shadows = 1;

	// #if defined(_SHADOW_MASK_ALWAYS)
	// 	gi.shadowMask.always = true;
	// 	gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, surfaceWS);
	// #elif defined(_SHADOW_MASK_DISTANCE)
	// 	gi.shadowMask.distance = true;
	// 	gi.shadowMask.shadows = SampleBakedShadows(lightMapUV, surfaceWS);
	// #endif

	return gi;
}


#endif