#ifndef BIOUM_COMMON_INCLUDE
#define BIOUM_COMMON_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

half Square(half v)
{
	return v * v;
}
half2 Square(half2 v)
{
	return v * v;
}
half3 Square(half3 v)
{
	return v * v;
}

float DistanceSquared(float3 pA, float3 pB) 
{
	return dot(pA - pB, pA - pB);
}

#endif