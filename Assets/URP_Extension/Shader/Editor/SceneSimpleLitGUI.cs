using UnityEditor;
using UnityEngine;

public class SceneSimpleLitGUI : ShaderGUI
{
    public enum BlendMode
    {
        Opaque,
        Cutout,
        Transparent,
        PreMultiply,
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
        public static readonly string[] blendNames = { "不透明", "透贴", "半透明", "预乘Alpha半透明" };
        public static readonly string[] cullNames = { "正面显示", "背面显示", "双面显示" };
        public static GUIContent baseMapText = new GUIContent("颜色贴图");
        public static GUIContent normalMapText = new GUIContent("法线贴图");
        public static GUIContent maseMapText = new GUIContent("自发光(R) AO(A)");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty baseMap = null;
    MaterialProperty baseColor = null;
    MaterialProperty normalMap = null;
    MaterialProperty normalScale = null;
    MaterialProperty normalMapSwitch = null;
    MaterialProperty maesMap = null;
    MaterialProperty emissiveColor = null;
    MaterialProperty AOStrength = null;
    MaterialProperty transparent = null;
    MaterialProperty transparentZWrite = null;
    MaterialProperty cutoutStrength = null;
    MaterialProperty sssToggle = null;
    MaterialProperty sssColor = null;
    MaterialProperty rimColor = null;
    MaterialProperty rimPower = null;
    MaterialProperty windToggle = null;
    MaterialProperty windScale = null;
    MaterialProperty windSpeed = null;
    MaterialProperty windDirection = null;
    MaterialProperty windIntensity = null;
    MaterialProperty windParam = null;
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
        maesMap = FindProperty("_MAESMap", props);
        emissiveColor = FindProperty("_EmiColor", props);
        AOStrength = FindProperty("_AOStrength", props);
        transparent = FindProperty("_Transparent", props);
        transparentZWrite = FindProperty("_TransparentZWrite", props);
        cutoutStrength = FindProperty("_Cutoff", props);
        sssToggle = FindProperty("_sssToggle", props);
        sssColor = FindProperty("_SSSColor", props);
        rimColor = FindProperty("_RimColor", props);
        rimPower = FindProperty("_RimPower", props);
        windToggle = FindProperty("_WindToggle", props);
        windScale = FindProperty("_WindScale", props);
        windSpeed = FindProperty("_WindSpeed", props);
        windDirection = FindProperty("_WindDirection", props);
        windIntensity = FindProperty("_WindIntensity", props);
        windParam = FindProperty("_WindParam", props);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        material.doubleSidedGI = true;

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
                material.SetMaterialKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Geometry;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetMaterialKeyword("_ALPHATEST_ON", true);
                material.SetMaterialKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", 1);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
            case BlendMode.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetMaterialKeyword("_ALPHATEST_ON", false);
                material.SetMaterialKeyword("_ALPHAPREMULTIPLY_ON", false);
                material.SetInt("_ZWrite", (int) transparentZWrite.floatValue);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.PreMultiply:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetMaterialKeyword("_ALPHATEST_ON", false);
                material.SetMaterialKeyword("_ALPHAPREMULTIPLY_ON", true);
                material.SetInt("_ZWrite", (int) transparentZWrite.floatValue);
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
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
        else if ((BlendMode) blendMode.floatValue == BlendMode.Transparent ||
            (BlendMode) blendMode.floatValue == BlendMode.PreMultiply)
        {
            m_MaterialEditor.ShaderProperty(transparent, "透明度", indent);
            m_MaterialEditor.ShaderProperty(transparentZWrite, "Z写入", indent);
            mainColor = baseColor.colorValue;
            mainColor.a = transparent.floatValue;
        }

        CullModePopup();

        EditorGUILayout.Space(10);
        m_MaterialEditor.TexturePropertySingleLine(Styles.baseMapText, baseMap, baseColor);
        m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, normalMap, normalScale);
        if (normalMap.textureValue != null)
            m_MaterialEditor.ShaderProperty(normalMapSwitch, "DX/OpenGL切换", indent);
        m_MaterialEditor.TexturePropertySingleLine(Styles.maseMapText, maesMap);

        { // for bake
            material.SetTexture("_MainTex", baseMap.textureValue);
            material.SetColor("_Color", mainColor);
        }

        material.SetMaterialKeyword("_MAESMAP", maesMap.textureValue != null);
        material.SetMaterialKeyword("_NORMALMAP", normalMap.textureValue != null);

        EditorGUILayout.Space();
        m_MaterialEditor.ShaderProperty(emissiveColor, "自发光");
        EditorGUI.BeginChangeCheck();
        m_MaterialEditor.LightmapEmissionProperty(indent);
        if (EditorGUI.EndChangeCheck())
        {
            material.globalIlluminationFlags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(AOStrength, "AO强度");

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(sssToggle, "SSS");
        if (sssToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(sssColor, "SSS颜色", indent);
        }

        EditorGUILayout.Space(10);
        m_MaterialEditor.ShaderProperty(windToggle, "风开关");
        if (windToggle.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(windScale, "缩放", indent);
            m_MaterialEditor.ShaderProperty(windSpeed, "速度", indent);
            m_MaterialEditor.ShaderProperty(windDirection, "风向", indent);
            m_MaterialEditor.ShaderProperty(windIntensity, "强度", indent);
            float radian = windDirection.floatValue * Mathf.Deg2Rad;
            float x = Mathf.Cos(radian) * windIntensity.floatValue;
            float y = Mathf.Sin(radian) * windIntensity.floatValue;
            windParam.vectorValue = new Vector4(x, y, windScale.floatValue, windSpeed.floatValue);
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