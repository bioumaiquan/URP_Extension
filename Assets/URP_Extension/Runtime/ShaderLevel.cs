using UnityEngine;

public static class ShaderLevel
{
    public delegate void LevelHandler();
    public static event LevelHandler LevelChanged;

    public enum Level { High, Medium, Low }
    static Level currentLevel = Level.High;
    public static Level CurrentLevel
    {
        get
        {
            SetShaderLOD();
            return currentLevel;
        }
        set
        {
            if (value != currentLevel)
            {
                currentLevel = value;
                SetShaderLOD();
                if (LevelChanged != null)
                {
                    LevelChanged();
                }
            }
        }
    }

    static void SetShaderLOD()
    {
        switch (currentLevel)
        {
            case Level.High:
                Shader.globalMaximumLOD = 300;
                break;
            case Level.Medium:
                Shader.globalMaximumLOD = 200;
                break;
            case Level.Low:
                Shader.globalMaximumLOD = 100;
                break;
        }
    }
}