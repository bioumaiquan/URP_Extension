using System.Collections;
using System.Collections.Generic;
using BioumRP;
using UnityEngine;

[ExecuteAlways]
public class SceneMainLight : MonoBehaviour
{
    public Light mainLight;

    void Update()
    {
        Shader.SetGlobalVector(ShaderPropertyIDs.Scene.MainLightDir, -mainLight.transform.forward);
        Color lightColor = mainLight.color.linear;
        lightColor = new Color(lightColor.r * mainLight.intensity, lightColor.g * mainLight.intensity, lightColor.b * mainLight.intensity);
        Shader.SetGlobalColor(ShaderPropertyIDs.Scene.MainLightColor, lightColor);
    }
}