using System.Collections;
using System.Collections.Generic;
using IDs = BioumRP.ShaderPropertyIDs;
using UnityEngine;

[ExecuteAlways]
public class CharacterUIConfig : MonoBehaviour
{
    public Cubemap environmentTexture;
    [ColorUsage(false, true)]
    public Color environmentColor = Color.grey;
    private void OnEnable()
    {
        OnValidate();
        Shader.EnableKeyword("_CHARACTER_IN_UI");
    }

    private void OnDisable()
    {
        Shader.DisableKeyword("_CHARACTER_IN_UI");
    }

    private void OnValidate()
    {
        if (environmentTexture != null)
        {
            environmentColor.a = environmentTexture.mipmapCount;
        }

        Shader.SetGlobalColor(IDs.Character.CharacterEnvironmentColor, environmentColor);
        Shader.SetGlobalTexture(IDs.Character.CharacterEnvironmentCube, environmentTexture);
    }
}