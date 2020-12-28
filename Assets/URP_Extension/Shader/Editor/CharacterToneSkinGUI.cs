using UnityEditor;
using UnityEngine;

public class CharacterToneSkinGUI : ShaderGUI
{
    private static class Styles
    {
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent maesMapText = new GUIContent("SSS强度(R) AO(G) 光滑(A)");
        public static GUIContent smoothnessRemapText = new GUIContent("光滑度重映射");
        public static GUIContent curveRemapText = new GUIContent("SSS强度重映射");
    }

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty normalMap = null;
    MaterialProperty normalScale = null;
    MaterialProperty maesMap = null;

    MaterialProperty smoothnessMin = null;
    MaterialProperty smoothnessMax = null;
    MaterialProperty curveMin = null;
    MaterialProperty curveMax = null;
    MaterialProperty smoothAndCurve = null;

    MaterialProperty AOStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;

    MaterialProperty rimToggle = null;
    MaterialProperty rimColorFront = null;
    MaterialProperty rimColorBack = null;
    MaterialProperty rimPower = null;
    MaterialProperty rimOffsetX = null;
    MaterialProperty rimOffsetY = null;
    MaterialProperty rimSmooth = null;
    MaterialProperty rimParam = null;

    MaterialProperty smoothDiff = null;
    MaterialProperty lightColorControl = null;
    MaterialProperty lightIntensity = null;

    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        normalMap = FindProperty("_NormalMap", props);
        normalScale = FindProperty("_NormalScale", props);
        maesMap = FindProperty("_MAESMap", props);

        smoothnessMin = FindProperty("_SmoothnessMin", props);
        smoothnessMax = FindProperty("_SmoothnessMax", props);
        curveMin = FindProperty("_CurveMin", props);
        curveMax = FindProperty("_CurveMax", props);
        smoothAndCurve = FindProperty("_SmoothAndCurve", props);

        AOStrength = FindProperty("_AOStrength", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);

        rimToggle = FindProperty("_RimToggle", props);
        rimColorFront = FindProperty("_RimColorFront", props);
        rimColorBack = FindProperty("_RimColorBack", props);
        rimOffsetX = FindProperty("_RimOffsetX", props);
        rimOffsetY = FindProperty("_RimOffsetY", props);
        rimSmooth = FindProperty("_RimSmooth", props);
        rimPower = FindProperty("_RimPower", props);
        rimParam = FindProperty("_RimParam", props);

        lightIntensity = FindProperty("_LightIntensity", props);
        lightColorControl = FindProperty("_LightColorControl", props);
        smoothDiff = FindProperty("_SmoothDiff", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        material.doubleSidedGI = true;

        FindProperties(props);
        ShaderPropertiesGUI(material);

        //EditorGUILayout.Space();
        //m_MaterialEditor.RenderQueueField();
        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    const int indent = 1;
    public void ShaderPropertiesGUI(Material material)
    {

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap, baseColor);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap, normalScale);
        // if (normalMap.textureValue != null)
        //     m_MaterialEditor.ShaderProperty(normalMapSwitch, "DX/OpenGL切换", indent);
        m_MaterialEditor.TexturePropertySingleLine(Styles.maesMapText, maesMap);

        material.SetMaterialKeyword("_NORMALMAP", normalMap.textureValue != null);

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(lightColorControl, "暗部颜色");
        m_MaterialEditor.ShaderProperty(lightIntensity, "灯光强度");
        m_MaterialEditor.ShaderProperty(smoothDiff, "明暗交界线硬度");
        Color colorControl = lightColorControl.colorValue;
        colorControl.a = lightIntensity.floatValue;
        lightColorControl.colorValue = colorControl;

        EditorGUILayout.Space(10);
         m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");
        if (maesMap.textureValue != null)
        {
            float sMin = smoothnessMin.floatValue;
            float sMax = smoothnessMax.floatValue;
            float cMin = curveMin.floatValue;
            float cMax = curveMax.floatValue;
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.MinMaxSlider(Styles.smoothnessRemapText, ref sMin, ref sMax, 0.0f, 1.0f);
            EditorGUILayout.MinMaxSlider(Styles.curveRemapText, ref cMin, ref cMax, 0.0f, 1.0f);
            if (EditorGUI.EndChangeCheck())
            {
                smoothnessMin.floatValue = sMin;
                smoothnessMax.floatValue = sMax;
                curveMin.floatValue = cMin;
                curveMax.floatValue = cMax;
                smoothAndCurve.vectorValue = new Vector4(sMin, sMax, cMin, cMax);
            }
        }
        else
        {
            m_MaterialEditor.ShaderProperty(smoothnessMax, "光滑度");
            m_MaterialEditor.ShaderProperty(curveMax, "SSS强度");
            smoothnessMin.floatValue = 0;
            curveMin.floatValue = 0;
            smoothAndCurve.vectorValue = new Vector4(smoothnessMin.floatValue, smoothnessMax.floatValue, curveMin.floatValue, curveMax.floatValue);
        }
       
        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(sssToggle, "SSS");
        if (sssToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(sssColor, "SSS颜色", indent);
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(rimToggle, "边缘光开关");
        if (rimToggle.floatValue != 0)
        {
            EditorGUI.indentLevel++;
            m_MaterialEditor.ShaderProperty(rimColorFront, "边缘光亮面颜色");
            m_MaterialEditor.ShaderProperty(rimColorBack, "边缘光暗面颜色");
            m_MaterialEditor.ShaderProperty(rimOffsetX, "亮面范围偏移");
            m_MaterialEditor.ShaderProperty(rimOffsetY, "暗面范围偏移");
            m_MaterialEditor.ShaderProperty(rimSmooth, "边缘光硬度");
            m_MaterialEditor.ShaderProperty(rimPower, "边缘光范围");
            EditorGUI.indentLevel--;
            rimParam.vectorValue = new Vector4(rimOffsetX.floatValue, rimOffsetY.floatValue, rimSmooth.floatValue, rimPower.floatValue);

        }
    }
}