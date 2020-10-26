using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class PostController : MonoBehaviour
{
    public Volume volume;
    public UniversalAdditionalCameraData cameraData;

    public VolumeProfile highLevelProfile;
    public VolumeProfile mediumLevelProfile;
    public VolumeProfile lowLevelProfile;

    private void OnEnable()
    {
        if (volume == null || highLevelProfile == null || mediumLevelProfile == null || lowLevelProfile == null)
            return;

        if (cameraData == null)
            return;

        SetVolumeProfile();

        ShaderLevel.LevelChanged += SetVolumeProfile;
    }

    private void OnDisable()
    {
        ShaderLevel.LevelChanged -= SetVolumeProfile;
    }

    void SetVolumeProfile()
    {
        switch (ShaderLevel.CurrentLevel)
        {
            case ShaderLevel.Level.High:
                volume.profile = highLevelProfile;
                cameraData.antialiasing = AntialiasingMode.SubpixelMorphologicalAntiAliasing;
                cameraData.antialiasingQuality = AntialiasingQuality.Medium;
                cameraData.renderShadows = true;
                break;
            case ShaderLevel.Level.Medium:
                volume.profile = mediumLevelProfile;
                cameraData.antialiasing = AntialiasingMode.FastApproximateAntialiasing;
                cameraData.renderShadows = true;
                break;
            case ShaderLevel.Level.Low:
                volume.profile = lowLevelProfile;
                cameraData.antialiasing = AntialiasingMode.None;
                cameraData.renderShadows = false;
                break;
        }
    }
}