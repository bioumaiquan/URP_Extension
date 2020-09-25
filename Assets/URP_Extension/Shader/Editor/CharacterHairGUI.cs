using UnityEditor;
using UnityEngine;

public class CharacterHairGUI : ShaderGUI
{
    public enum BlendMode
    {
        Opaque,
        Cutout,
    }
    public enum CullMode
    {
        Back,
        Front,
        Double,
    }

    private static class Styles
    {
        public static string renderingMode = "混合模式";
        public static string cullingMode = "裁剪模式";
        public static readonly string[] blendNames = { "不透明", "透贴", };
        public static readonly string[] cullNames = { "正面显示", "背面显示", "双面显示" };
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent maskMapText = new GUIContent("(R)偏移 (A)AO");
        public static GUIContent smoothnessRemapText = new GUIContent("光滑度重映射");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty normalMap = null;
    MaterialProperty normalScale = null;
    MaterialProperty normalMapSwitch = null;
    MaterialProperty maskMap = null;
    MaterialProperty smoothness = null;
    MaterialProperty metallic = null;
    MaterialProperty fresnelStrength = null;
    MaterialProperty AOStrength = null;
    MaterialProperty cutoutStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;
    MaterialProperty rimColor = null;
    MaterialProperty rimPower = null;
    MaterialProperty switchTangent = null;
    MaterialProperty doubleSpecular = null;
    MaterialProperty intensity = null;
    MaterialProperty shift = null;
    MaterialProperty subSmoothness = null;
    MaterialProperty subShift = null;
    MaterialProperty subIntensity = null;
    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_BlendMode", props);
        cullMode = FindProperty("_CullMode", props);
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        normalMap = FindProperty("_NormalMap", props);
        normalScale = FindProperty("_NormalScale", props);
        normalMapSwitch = FindProperty("_NormalMapDXGLSwitch", props);
        maskMap = FindProperty("_MaskMap", props);
        smoothness = FindProperty("_Smoothness", props);
        metallic = FindProperty("_Metallic", props);
        fresnelStrength = FindProperty("_FresnelStrength", props);
        AOStrength = FindProperty("_AOStrength", props);
        cutoutStrength = FindProperty("_Cutoff", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);
        rimColor = FindProperty("_RimColor", props);
        rimPower = FindProperty("_RimPower", props);
        shift = FindProperty("_Shift", props);
        subShift = FindProperty("_SubShift", props);
        subSmoothness = FindProperty("_SubSmoothness", props);
        subIntensity = FindProperty("_SubIntensity", props);
        doubleSpecular = FindProperty("_DoubleSpecular", props);
        intensity = FindProperty("_Intensity", props);
        switchTangent = FindProperty("_SwitchTangent", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        FindProperties(props);
        RenderMode(material);
        ShaderPropertiesGUI(material);

        //EditorGUILayout.Space();
        //m_MaterialEditor.RenderQueueField();
        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    void RenderMode(Material material)
    {
        SetupMaterialWithBlendMode(material, (BlendMode) blendMode.floatValue);
        SetupMaterialWithCullMode(material, (CullMode) cullMode.floatValue);
    }

    public void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetMaterialKeyword("_ALPHATEST_ON", false);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Geometry;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetMaterialKeyword("_ALPHATEST_ON", true);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
        }
    }

    public void SetupMaterialWithCullMode(Material material, CullMode cullMode)
    {
        switch (cullMode)
        {
            case CullMode.Back:
                material.SetInt("_Cull", (int) UnityEngine.Rendering.CullMode.Back);
                break;
            case CullMode.Front:
                material.SetInt("_Cull", (int) UnityEngine.Rendering.CullMode.Front);
                break;
            case CullMode.Double:
                material.SetInt("_Cull", (int) UnityEngine.Rendering.CullMode.Off);
                break;
        }
    }

    const int indent = 1;
    public void ShaderPropertiesGUI(Material material)
    {

        BlendModePopup();

        Color mainColor = Color.white;

        if ((BlendMode) blendMode.floatValue == BlendMode.Cutout)
        {
            m_MaterialEditor.ShaderProperty(cutoutStrength, "透贴强度", indent);
        }

        CullModePopup();

        m_MaterialEditor.ShaderProperty(switchTangent, "高光方向切换", indent);

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap, baseColor);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap, normalScale);
        if (normalMap.textureValue != null)
            m_MaterialEditor.ShaderProperty(normalMapSwitch, "DX/OpenGL切换", indent);
        material.SetMaterialKeyword("_NORMALMAP", normalMap.textureValue != null);

        m_MaterialEditor.TexturePropertySingleLine(Styles.maskMapText, maskMap);

        EditorGUILayout.Space(10);

        m_MaterialEditor.ShaderProperty(metallic, "金属度");
        m_MaterialEditor.ShaderProperty(fresnelStrength, "菲涅尔强度");
        m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(smoothness, "光滑度");
        m_MaterialEditor.ShaderProperty(intensity, "高光强度");
        m_MaterialEditor.ShaderProperty(shift, "高光偏移");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(doubleSpecular, "双层高光");
        if (doubleSpecular.floatValue != 0)
        {
            EditorGUI.indentLevel += indent;
            m_MaterialEditor.ShaderProperty(subSmoothness, "光滑度");
            m_MaterialEditor.ShaderProperty(subIntensity, "高光强度");
            m_MaterialEditor.ShaderProperty(subShift, "高光偏移");
            EditorGUI.indentLevel -= indent;
        }

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

    void BlendModePopup()
    {
        EditorGUI.showMixedValue = blendMode.hasMixedValue;
        var mode = (BlendMode) blendMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode) EditorGUILayout.Popup(Styles.renderingMode, (int) mode, Styles.blendNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            blendMode.floatValue = (float) mode;
        }

        EditorGUI.showMixedValue = false;
    }

    void CullModePopup()
    {
        EditorGUI.showMixedValue = cullMode.hasMixedValue;
        var mode = (CullMode) cullMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (CullMode) EditorGUILayout.Popup(Styles.cullingMode, (int) mode, Styles.cullNames);

        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Culling Mode");
            cullMode.floatValue = (float) mode;
        }

        EditorGUI.showMixedValue = false;
    }

}