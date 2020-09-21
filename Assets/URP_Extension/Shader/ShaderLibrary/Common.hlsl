#ifndef BIOUM_COMMON_INCLUDE
#define BIOUM_COMMON_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


real Square(real v)
{
	return v * v;
}
real2 Square(real2 v)
{
	return v * v;
}
real3 Square(real3 v)
{
	return v * v;
}

real DistanceSquared(float3 pA, float3 pB) 
{
	return dot(pA - pB, pA - pB);
}

real positiveSin(real x)
{
    x = fmod(x, TWO_PI);
    return sin(x) * 0.5 + 0.5;
}

real4 LerpWhiteTo(real4 b, real t)
{
    real oneMinusT = 1.0 - t;
    return real4(oneMinusT, oneMinusT, oneMinusT, oneMinusT) + b * t;
}

TEXTURE2D_FLOAT(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);
real SoftEdge(real near, real far, real4 positionNDC)
{
    positionNDC.xyz /= positionNDC.w;
    float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, positionNDC.xy).r;
    real sceneZ = LinearEyeDepth(depth, _ZBufferParams);
    real thisZ = LinearEyeDepth(positionNDC.z, _ZBufferParams);
    real fade = saturate (far * ((sceneZ - near) - thisZ));
    return fade;
}


#endif