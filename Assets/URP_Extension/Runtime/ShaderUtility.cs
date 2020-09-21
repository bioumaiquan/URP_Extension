using UnityEditor;
using UnityEngine;
public static class ShaderUtility
{
    public static void SetMaterialKeyword(this Material material, string keyWord, bool toggle)
    {
        if (toggle)
            material.EnableKeyword(keyWord);
        else
            material.DisableKeyword(keyWord);
    }
}