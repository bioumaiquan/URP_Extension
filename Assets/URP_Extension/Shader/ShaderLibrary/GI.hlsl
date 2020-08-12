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


half3 SampleEnvironment (Surface surfaceWS, BRDF brdf) 
{
    half3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
    half lod = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
    half4 baseEnv = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, lod);
    half4 env = baseEnv;

    UNITY_BRANCH
    if (brdf.clearCoat > 0.005)
    {
        half3 clearCoatUVW = reflect(-surfaceWS.viewDirection, surfaceWS.clearCoatNormal);
        half4 clearCoatEnv = SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, clearCoatUVW);
        env = lerp(baseEnv, clearCoatEnv, brdf.clearCoat);
    }
    return DecodeHDREnvironment(env, unity_SpecCube0_HDR);
}



struct GI 
{
    half3 diffuse;
    half3 specular;
};

GI GetGI (half2 lightMapUV, half3 vertexSH, Surface surfaceWS, BRDF brdf) 
{
    GI gi;
    
    gi.diffuse = SampleLightmap(lightMapUV, surfaceWS.normal) + vertexSH;
    gi.specular = SampleEnvironment(surfaceWS, brdf);

    return gi;
}


#ifdef LIGHTMAP_ON
#define GET_GI(lmName, shName, normalWSName, brdfName) GetGI(lmName, 0, normalWSName, brdfName)
#else
#define GET_GI(lmName, shName, normalWSName, brdfName) GetGI(0, shName, normalWSName, brdfName)
#endif


#endif