using UnityEditor;
using UnityEngine;

public class CharacterSkinGUI : ShaderGUI
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
    MaterialProperty normalMapSwitch = null;
    MaterialProperty maesMap = null;
    MaterialProperty smoothnessMin = null;
    MaterialProperty smoothnessMax = null;
    MaterialProperty curveMin = null;
    MaterialProperty curveMax = null;
    MaterialProperty smoothCurve = null;
    MaterialProperty fresnelStrength = null;
    MaterialProperty AOStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;
    MaterialProperty rimColor = null;
    MaterialProperty rimPower = null;
    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        normalMap = FindProperty("_NormalMap", props);
        normalScale = FindProperty("_NormalScale", props);
        normalMapSwitch = FindProperty("_NormalMapDXGLSwitch", props);
        maesMap = FindProperty("_MAESMap", props);
        smoothnessMin = FindProperty("_SmoothnessMin", props);
        smoothnessMax = FindProperty("_SmoothnessMax", props);
        curveMin = FindProperty("_CurveMin", props);
        curveMax = FindProperty("_CurveMax", props);
        smoothCurve = FindProperty("_SmoothCurve", props);
        fresnelStrength = FindProperty("_FresnelStrength", props);
        AOStrength = FindProperty("_AOStrength", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);
        rimColor = FindProperty("_RimColor", props);
        rimPower = FindProperty("_RimPower", props);
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

        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap, baseColor);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap, normalScale);
        if (normalMap.textureValue != null)
            m_MaterialEditor.ShaderProperty(normalMapSwitch, "DX/OpenGL切换", indent);
        m_MaterialEditor.TexturePropertySingleLine(Styles.maesMapText, maesMap);

        material.SetMaterialKeyword("_NORMALMAP", normalMap.textureValue != null);

        EditorGUILayout.Space(10);
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
                smoothCurve.vectorValue = new Vector4(sMin, sMax, cMin, cMax);
            }
        }
        else
        {
            m_MaterialEditor.ShaderProperty(smoothnessMax, "光滑度");
            m_MaterialEditor.ShaderProperty(curveMax, "SSS强度");
            smoothnessMin.floatValue = 0;
            curveMin.floatValue = 0;
        }
        m_MaterialEditor.ShaderProperty(fresnelStrength, "菲涅尔强度");
        m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(sssToggle, "SSS");
        if (sssToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(sssColor, "SSS颜色", indent);
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(this.rimColor, "边缘光颜色");
        m_MaterialEditor.ShaderProperty(rimPower, "边缘光范围");
        Color rimColor = this.rimColor.colorValue;
        rimColor.a = rimPower.floatValue;
        this.rimColor.colorValue = rimColor;
        material.SetMaterialKeyword("_RIM", rimColor.maxColorComponent >= 0.04f);
    }
}