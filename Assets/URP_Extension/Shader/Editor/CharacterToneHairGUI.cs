using UnityEditor;
using UnityEngine;

public class CharacterToneHairGUI : ShaderGUI
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
        public static GUIContent maskMapText = new GUIContent("AO(R) 偏移(A)");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty normalMap = null;
    MaterialProperty normalScale = null;
    MaterialProperty maskMap = null;
    MaterialProperty smoothness = null;
    MaterialProperty metallic = null;
    MaterialProperty fresnelStrength = null;
    MaterialProperty AOStrength = null;
    MaterialProperty cutoutStrength = null;
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

    MaterialProperty switchTangent = null;
    MaterialProperty doubleSpecular = null;
    MaterialProperty specIntensity = null;
    MaterialProperty shift = null;
    MaterialProperty subSmoothness = null;
    MaterialProperty subShift = null;
    MaterialProperty subSpecIntensity = null;

    MaterialProperty smoothDiff = null;
    MaterialProperty lightColorControl = null;
    MaterialProperty lightIntensity = null;

    MaterialEditor m_MaterialEditor;

    public void FindProperties(MaterialProperty[] props)
    {
        blendMode = FindProperty("_BlendMode", props);
        cullMode = FindProperty("_CullMode", props);
        baseMap = FindProperty("_BaseMap", props);
        baseColor = FindProperty("_BaseColor", props);
        normalMap = FindProperty("_NormalMap", props);
        normalScale = FindProperty("_NormalScale", props);
        maskMap = FindProperty("_MAESMap", props);
        smoothness = FindProperty("_Smoothness", props);
        metallic = FindProperty("_Metallic", props);
        fresnelStrength = FindProperty("_FresnelStrength", props);
        AOStrength = FindProperty("_AOStrength", props);
        cutoutStrength = FindProperty("_Cutoff", props);
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

        shift = FindProperty("_Shift", props);
        subShift = FindProperty("_SubShift", props);
        subSmoothness = FindProperty("_SubSmoothness", props);
        subSpecIntensity = FindProperty("_SubSpecIntensity", props);
        doubleSpecular = FindProperty("_DoubleSpecular", props);
        specIntensity = FindProperty("_SpecIntensity", props);
        switchTangent = FindProperty("_SwitchTangent", props);

        lightIntensity = FindProperty("_LightIntensity", props);
        lightColorControl = FindProperty("_LightColorControl", props);
        smoothDiff = FindProperty("_SmoothDiff", props);
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
        material.SetMaterialKeyword("_NORMALMAP", normalMap.textureValue != null);

        m_MaterialEditor.TexturePropertySingleLine(Styles.maskMapText, maskMap);

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(lightColorControl, "暗部颜色");
        m_MaterialEditor.ShaderProperty(lightIntensity, "灯光强度");
        m_MaterialEditor.ShaderProperty(smoothDiff, "明暗交界线硬度");
        Color colorControl = lightColorControl.colorValue;
        colorControl.a = lightIntensity.floatValue;
        lightColorControl.colorValue = colorControl;


        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(metallic, "金属度");
        m_MaterialEditor.ShaderProperty(fresnelStrength, "菲涅尔强度");
        m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(smoothness, "光滑度");
        m_MaterialEditor.ShaderProperty(specIntensity, "高光强度");
        m_MaterialEditor.ShaderProperty(shift, "高光偏移");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(doubleSpecular, "双层高光");
        if (doubleSpecular.floatValue != 0)
        {
            EditorGUI.indentLevel += indent;
            m_MaterialEditor.ShaderProperty(subSmoothness, "光滑度");
            m_MaterialEditor.ShaderProperty(subSpecIntensity, "高光强度");
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
        m_MaterialEditor.ShaderProperty(rimToggle, "边缘光开关");
        if(rimToggle.floatValue != 0)
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