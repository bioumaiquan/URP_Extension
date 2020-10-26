#ifndef BIOUM_GI_INCLUDE
#define BIOUM_GI_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"

#ifdef LIGHTMAP_ON
#define DECLARE_GI_DATA(lmName, shName, index) float2 lmName : TEXCOORD##index
#define OUTPUT_GI_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
#define OUTPUT_GI_SH(normalWS, OUT)
#else
#define DECLARE_GI_DATA(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_GI_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
#define OUTPUT_GI_SH(normalWS, OUT) OUT.xyz = SampleSH(normalWS)
#endif

#if _CHARACTER_IN_UI
TEXTURECUBE(_CharacterEnvironmentCube);
SAMPLER(sampler_CharacterEnvironmentCube);
half4 _CharacterEnvironmentCube_HDR;
half4 _CharacterEnvironmentColor; // a : cube mipmap count
#endif



half3 SampleEnvironment (Surface surfaceWS, BRDF brdf) 
{
    half3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
    
    #if _CHARACTER_IN_UI
        half lod = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness, (uint)_CharacterEnvironmentColor.a);
        half4 environment = SAMPLE_TEXTURECUBE_LOD(_CharacterEnvironmentCube, sampler_CharacterEnvironmentCube, uvw, lod);
        half3 color = DecodeHDREnvironment(environment, _CharacterEnvironmentCube_HDR);
    #else
        half lod = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
        half4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, lod);
        half3 color = DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
    #endif

    return color;
}

half4 SampleShadowMask(half2 lightmapUV)
{
    half shadowStrength = GetMainLightShadowParams().x;
    half4 shadowMask = SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, lightmapUV);
    shadowMask = LerpWhiteTo(shadowMask, shadowStrength);
    return shadowMask;
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

// Samples SH L0, L1 and L2 terms
half3 SampleSH(half3 normalWS)
{
    #if _CHARACTER_IN_UI
        return _CharacterEnvironmentColor.rgb;
    #else
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
    #endif
}



struct GI 
{
    half3 diffuse;
    half3 specular;
    half shadowMask;
};

GI GetSimpleGI (half2 lightMapUV, half3 vertexSH, Surface surfaceWS) 
{
    GI gi;
    gi.diffuse = SampleLightmap(lightMapUV, surfaceWS.normal) + vertexSH;
    #if _CHARACTER_IN_UI
        gi.specular = _CharacterEnvironmentColor.rgb;
    #else
        gi.specular = _GlossyEnvironmentColor.rgb;
    #endif
    gi.shadowMask = 1;
    #if SHADOWS_SHADOWMASK && LIGHTMAP_ON
        gi.shadowMask = SampleShadowMask(lightMapUV).r;
    #endif
    return gi;
}
GI GetGI (half2 lightMapUV, half3 vertexSH, Surface surfaceWS, BRDF brdf) 
{
    GI gi;
    gi = GetSimpleGI(lightMapUV, vertexSH, surfaceWS);
    #if _ENVIRONMENT_REFLECTION_ON
        gi.specular = SampleEnvironment(surfaceWS, brdf);
    #endif
    return gi;
}

#ifdef LIGHTMAP_ON
#define GET_GI(lmName, shName, normalWSName, brdfName) GetGI(lmName, 0, normalWSName, brdfName)
#define GET_SIMPLE_GI(lmName, shName, normalWSName) GetSimpleGI(lmName, 0, normalWSName)
#else
#define GET_GI(lmName, shName, normalWSName, brdfName) GetGI(0, shName, normalWSName, brdfName)
#define GET_SIMPLE_GI(lmName, shName, normalWSName) GetSimpleGI(0, shName, normalWSName)
#endif


#endif