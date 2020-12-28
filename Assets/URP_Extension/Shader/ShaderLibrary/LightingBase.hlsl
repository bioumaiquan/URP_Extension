#ifndef BIOUM_LIGHTING_BASE_INCLUDED
#define BIOUM_LIGHTING_BASE_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Light.hlsl"
#include "BRDF.hlsl"
#include "GI.hlsl"




// 球面高斯SSS 
// https://zhuanlan.zhihu.com/p/139836594
struct FSphericalGausian
{
    half3 Axis;
    half3 Sharpness;
    //half3 Amplitude;
};

half3 DotCosineLobe(FSphericalGausian SG, half3 normalWS)
{
    half muDotN = dot(SG.Axis, normalWS);
    half c0 = 0.36, c1 = 0.25 / c0;

    half3 eml = exp(-SG.Sharpness);
    half3 em2l = eml * eml;
    half3 rl = rcp(SG.Sharpness);

    half3 scale = 1 + 2 * em2l - rl;
    half3 bias = (eml - em2l) * rl - em2l;

    half3 x = sqrt(1 - scale);
    half3 x0 = c0 * muDotN;
    half3 x1 = c1 * x;

    half3 n = x0 + x1;
    half3 y = (abs(x0) <= x1) ? n * n / x : saturate(muDotN);

    return scale * y + bias;
}
FSphericalGausian MakeNormalizedSG(half3 lightDirWS, half3 sharpness)
{
    FSphericalGausian SG;
    SG.Axis = lightDirWS;
    SG.Sharpness = sharpness;
    //SG.Amplitude = SG.Sharpness / (TWO_PI * (1 - exp(-2 * SG.Sharpness)));
    return SG;
}
half3 SGDiffuseLighting(half3 normalWS, half3 lightDirWS, half3 SSSColor)
{
    FSphericalGausian rgbKernel = MakeNormalizedSG(lightDirWS, rcp(max(SSSColor, 0.001)));
    half3 diffuse = DotCosineLobe(rgbKernel, normalWS);
    
    return diffuse;
}

half3 SimpleSSS(Surface surface, half3 lightDirWS, half dirDistort)
{
    half3 backLightDir = surface.normal * dirDistort + lightDirWS;
    half sss = saturate(dot(surface.viewDirection, -backLightDir) * 0.5 + 0.5);
    return sss * sss * surface.SSSColor.rgb;
}

// SSS term

half3 RimColor(half3 lightDirWS, half3 normalWS, half3 viewDirWS, half4 rimColor)
{
    half3 backLightDir = lightDirWS; // * half3(1, 0.5, 1);
    half NdotV = abs(dot(normalWS, viewDirWS));
    half NdotBL = dot(normalWS, backLightDir) * 0.5 + 0.5;
    half2 range = PositivePow(half2(1 - NdotV, NdotBL), rimColor.a);

    return range.yyy * range.xxx * rimColor.rgb;
}


half SpecularStrength(Surface surface, BRDF brdf, Light light)
{
    half3 h = SafeNormalize(light.direction + surface.viewDirection);
    half nh2 = Square(saturate(dot(surface.normal, h)));
    half lh2 = Square(saturate(dot(light.direction, h)));
    half d2 = Square(nh2 * brdf.roughness2MinusOne + 1.00001);
    half spec = brdf.roughness2 / (d2 * max(0.1, lh2) * brdf.normalizationTerm);
    spec = min(100, spec);
    return spec;
}

half3 IndirectBRDF(Surface surface, BRDF brdf, half3 diffuse, half3 specular)
{
    
    half fresnelStrength = Pow4(1.0 - abs(dot(surface.normal, surface.viewDirection)));
    fresnelStrength *= surface.fresnelStrength;

    half3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
    reflection /= brdf.roughness2 + 1.0;
    
    // 让朝向地面方向的环境反射变暗
    //half NdotU = surface.normal.y * 0.5 + 0.5; //surface.normal = dot(surface.normal, (0,1,0))

    return diffuse * brdf.diffuse + reflection; // * NdotU;
}



#endif  //BIOUM_LIGHTING_BASE_INCLUDED