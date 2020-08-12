using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using IDs = BioumRP.ShaderPropertyIDs;

[ExecuteAlways]
public class Sky : MonoBehaviour
{
    [GradientUsage(true)]
    public Gradient skyColor;
    [Range(0, 0.005f)]
    public float sunSize = 0.05f;
    Color[] m_SkyColors = new Color[4] { Color.white, Color.white, Color.white, Color.white, };

    private void OnValidate()
    {
        Material skyMat = RenderSettings.skybox;
        if (skyMat == null || skyColor == null)
        {
            return;
        }

        m_SkyColors[0] = skyColor.colorKeys[0].color;
        m_SkyColors[0].a = sunSize;

        int count = skyColor.colorKeys.Length;
        if (count >= 4)
        {
            for (int i = 1; i < 4; i++)
            {
                m_SkyColors[i] = skyColor.colorKeys[i].color;
                m_SkyColors[i].a = skyColor.colorKeys[i].time;
            }
        }
        else if (count == 3)
        {
            m_SkyColors[1] = skyColor.colorKeys[1].color;
            m_SkyColors[1].a = skyColor.colorKeys[1].time;
            m_SkyColors[2] = Color.Lerp(skyColor.colorKeys[1].color, skyColor.colorKeys[2].color, 0.5f);
            m_SkyColors[2].a = Mathf.Lerp(skyColor.colorKeys[1].time, skyColor.colorKeys[2].time, 0.5f);
            m_SkyColors[3] = skyColor.colorKeys[2].color;
            m_SkyColors[3].a = skyColor.colorKeys[2].time;
        }
        else if (count <= 2)
        {
            m_SkyColors[1] = Color.Lerp(skyColor.colorKeys[0].color, skyColor.colorKeys[1].color, 0.333f);
            m_SkyColors[1].a = Mathf.Lerp(0, skyColor.colorKeys[1].time, 0.333f);
            m_SkyColors[2] = Color.Lerp(skyColor.colorKeys[0].color, skyColor.colorKeys[1].color, 0.667f);
            m_SkyColors[2].a = Mathf.Lerp(0, skyColor.colorKeys[1].time, 0.667f);
            m_SkyColors[3] = skyColor.colorKeys[1].color;
            m_SkyColors[3].a = skyColor.colorKeys[1].time;
        }

        // SetColorArray()会导致无法烘焙, 原因不明
        skyMat.SetColor(IDs.Scene.SkyColors0, m_SkyColors[0]);
        skyMat.SetColor(IDs.Scene.SkyColors1, m_SkyColors[1]);
        skyMat.SetColor(IDs.Scene.SkyColors2, m_SkyColors[2]);
        skyMat.SetColor(IDs.Scene.SkyColors3, m_SkyColors[3]);
    }
}