using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LevelChange : MonoBehaviour
{
    public void SetHighLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.High;
    }

    public void SetMediumLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.Medium;
    }

    public void SetLowLevel()
    {
        ShaderLevel.CurrentLevel = ShaderLevel.Level.Low;
    }
}