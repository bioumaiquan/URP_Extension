using UnityEditor;

public class ShaderLevelPreview : Editor
{
    [MenuItem("画面配置预览/高")]
    static void ShowHighLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.High;
    }

    [MenuItem("画面配置预览/中")]
    static void ShowMediumLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.Medium;
    }

    [MenuItem("画面配置预览/低")]
    static void ShowLowLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.Low;
    }
}