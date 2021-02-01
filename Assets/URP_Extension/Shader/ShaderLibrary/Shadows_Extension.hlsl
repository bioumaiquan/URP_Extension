#ifndef BIOUM_SHADOWS_INCLUDED
#define BIOUM_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
// half4 GetMainLightShadowParams()
// {
//     return _MainLightShadowParams;
// }

// extension shadow param
// z: 1.0 / shadowDistance
// w: 1.0 / shadowFade



half ShadowDistanceFade (float distance, float scale, float fade) 
{
	return saturate((1.0 - distance * scale) * fade);
}
half MainLightRealtimeShadow(float4 shadowCoord, float3 positionWS)
{
#if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    return 1.0h;
#endif

    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    half shadow = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);

    float dist = distance(positionWS, _WorldSpaceCameraPos.xyz);
    half fade = ShadowDistanceFade(dist, shadowParams.z, shadowParams.w);

    shadow = LerpWhiteTo(shadow, fade);

    return shadow;
}

#endif