using UnityEngine;

namespace BioumRP
{
    public class ShaderPropertyIDs
    {
        public class Scene
        {
            internal static readonly int MainLightDir = Shader.PropertyToID("g_MainLightDir");
            internal static readonly int MainLightColor = Shader.PropertyToID("g_MainLightColor");
            internal static readonly int FogColor = Shader.PropertyToID("g_FogColor");
            internal static readonly int FogSunColor = Shader.PropertyToID("g_FogSunColor");
            internal static readonly int FogParam = Shader.PropertyToID("g_FogParam");
            internal static readonly int WindParam = Shader.PropertyToID("g_WindParam");
            internal static readonly int SkyColors = Shader.PropertyToID("_SkyColors");
            internal static readonly int SkyColors0 = Shader.PropertyToID("_SkyColors0");
            internal static readonly int SkyColors1 = Shader.PropertyToID("_SkyColors1");
            internal static readonly int SkyColors2 = Shader.PropertyToID("_SkyColors2");
            internal static readonly int SkyColors3 = Shader.PropertyToID("_SkyColors3");
            internal static readonly int reflectionTexture = Shader.PropertyToID("_ReflectionTex");
            internal static readonly int reflectionTransparent = Shader.PropertyToID("_ReflectionTransparent");
        }

        public class Effect
        {

        }

        public class Character
        {

        }
    }
}