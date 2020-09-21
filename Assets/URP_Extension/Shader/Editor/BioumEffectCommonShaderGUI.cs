using UnityEditor;
using UnityEngine;

public class BioumEffectCommonShaderGUI : ShaderGUI
{
    public enum BlendMode
    {
        PreMultiply,
        Additive,
        AdditiveSoft,
        AlphaBlend,
        Multiply,
        Opaque,
        AlphaTest,
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
        public static readonly string[] blendNames = { "预乘alpha", "Add", "Soft Add", "Blend", "乘法", "不透明", "透贴" };
        public static readonly string[] cullNames = { "正面显示", "背面显示", "双面显示" };
        public static GUIContent albedoText = new GUIContent("贴图1", "RGBA");
        public static GUIContent secondaryAlbedoText = new GUIContent("贴图2", "RGBA");
        public static GUIContent distortText = new GUIContent("扰乱贴图", "使用R通道");
        public static GUIContent enableDistortText = new GUIContent("扰乱", "是否开启扰乱");
        public static GUIContent maskText = new GUIContent("遮罩贴图", "使用R通道");
        public static GUIContent enableMaskText = new GUIContent("遮罩", "是否开启遮罩");
        public static GUIContent enableRimText = new GUIContent("边缘光", "是否开启边缘光");
        public static GUIContent enableDissolveText = new GUIContent("溶解", "是否开启溶解");
        public static GUIContent dissolveText = new GUIContent("溶解贴图", "使用R通道");
    }

    MaterialProperty blendMode = null;
    MaterialProperty cullMode = null;

    MaterialProperty albedoMap = null;
    MaterialProperty albedoMapSecondary = null;
    MaterialProperty enableSecondaryAlbedo = null;
    MaterialProperty texBlendMode = null;
    MaterialProperty albedoAni = null;

    MaterialProperty distortMap = null;
    MaterialProperty secondaryDistortMap = null;
    MaterialProperty distort = null;
    MaterialProperty distortAni = null;
    MaterialProperty distortFactor = null;

    MaterialProperty color = null;
    MaterialProperty backColor = null;

    MaterialProperty mask = null;
    MaterialProperty maskMap = null;

    MaterialProperty rim = null;
    MaterialProperty rimPower = null;
    MaterialProperty rimColor = null;

    MaterialProperty dissolve = null;
    MaterialProperty dissolveFactor = null;
    MaterialProperty dissolveMap = null;
    MaterialProperty dissolveEdge = null;
    MaterialProperty dissolveSoft = null;
    MaterialProperty dissolveMode = null;
    MaterialProperty dissolveEdgeColor = null;

    MaterialProperty isParticle = null;
    MaterialProperty cutoff = null;

    MaterialEditor m_MaterialEditor;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        FindProperties(props, material);
        MaterialChanged(material);

        ShaderPropertiesGUI(material);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        EditorGUI.BeginChangeCheck();
        {
            BlendModePopup();
            if ((BlendMode) blendMode.floatValue == BlendMode.AlphaTest)
            {
                m_MaterialEditor.ShaderProperty(cutoff, "透贴强度", 1);
            }

            CullModePopup();
            m_MaterialEditor.ShaderProperty(isParticle, "是否用于粒子发射器");
            EditorGUILayout.Space();

            m_MaterialEditor.ColorProperty(color, "颜色");

            EditorGUILayout.Space();

            DoAlbedoArea(material);

            GUILayout.Label("-------------------------------------------", EditorStyles.centeredGreyMiniLabel);
            DoSecondaryAlbedoArea();

            GUILayout.Label("-------------------------------------------", EditorStyles.centeredGreyMiniLabel);
            DoDistortArea(material);

            GUILayout.Label("-------------------------------------------", EditorStyles.centeredGreyMiniLabel);
            DoMaskArea(material);

            GUILayout.Label("-------------------------------------------", EditorStyles.centeredGreyMiniLabel);
            DoRimArea(material);

            GUILayout.Label("-------------------------------------------", EditorStyles.centeredGreyMiniLabel);
            DoDissolveArea(material);
        }

        EditorGUILayout.Space();

        //m_MaterialEditor.RenderQueueField();
        //m_MaterialEditor.EnableInstancingField();
        //m_MaterialEditor.DoubleSidedGIField();
    }

    public void FindProperties(MaterialProperty[] props, Material material)
    {
        blendMode = FindProperty("_BlendMode", props);
        cullMode = FindProperty("_CullMode", props);

        albedoMap = FindProperty("_MainTex", props);
        albedoMapSecondary = FindProperty("_SecondaryTex", props);
        texBlendMode = FindProperty("_TexBlendMode", props);
        enableSecondaryAlbedo = FindProperty("_EnableSecondaryTex", props);
        albedoAni = FindProperty("_MainTexUVAni", props);

        color = FindProperty("_TintColor", props);

        distortMap = FindProperty("_DistortMap", props);
        secondaryDistortMap = FindProperty("_SecondaryDistortMap", props);
        distort = FindProperty("_Distort", props);
        distortAni = FindProperty("_DistortUVAni", props);
        distortFactor = FindProperty("_DistortFactor", props);

        maskMap = FindProperty("_MaskMap", props);
        mask = FindProperty("_Mask", props);

        rim = FindProperty("_Rim", props);
        rimPower = FindProperty("_rimPower", props);
        rimColor = FindProperty("_rimColor", props);

        dissolve = FindProperty("_Dissolve", props);
        dissolveFactor = FindProperty("_DissolveFactor", props);
        dissolveMap = FindProperty("_DissolveMap", props);
        dissolveEdge = FindProperty("_DissolveEdge", props);
        dissolveSoft = FindProperty("_DissolveSoft", props);
        dissolveEdgeColor = FindProperty("_DissolveEdgeColor", props);
        dissolveMode = FindProperty("_DissolveMode", props);

        isParticle = FindProperty("_IsParticle", props);
        cutoff = FindProperty("_Cutoff", props);
    }

    void MaterialChanged(Material material)
    {
        SetupMaterialWithBlendMode(material, (BlendMode) blendMode.floatValue);
        SetupMaterialWithCullMode(material, (CullMode) cullMode.floatValue);
    }

    public void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.PreMultiply:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.EnableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Additive:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.AdditiveSoft:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcColor);
                material.EnableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.SetInt("_ZWrite", 0);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.AlphaBlend:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.DisableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.SetInt("_ZWrite", 0);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Multiply:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.DstColor);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.SrcColor);
                material.DisableKeyword("_ADDITIVESOFT_ON");
                material.EnableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.SetInt("_ZWrite", 0);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.DisableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.SetInt("_ZWrite", 1);
                material.renderQueue = (int) UnityEngine.Rendering.RenderQueue.Geometry;
                break;
            case BlendMode.AlphaTest:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInt("_SrcBlend", (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int) UnityEngine.Rendering.BlendMode.Zero);
                material.DisableKeyword("_ADDITIVESOFT_ON");
                material.DisableKeyword("_MULTIPLY_ON");
                material.EnableKeyword("_ALPHATEST_ON");
                material.SetInt("_ZWrite", 1);
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

    void DoAlbedoArea(Material material)
    {
        m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap);
        m_MaterialEditor.TextureScaleOffsetProperty(albedoMap);
        m_MaterialEditor.ShaderProperty(albedoAni, "UV动画 XY贴图1 ZW贴图2");
    }

    void DoSecondaryAlbedoArea()
    {
        m_MaterialEditor.ShaderProperty(enableSecondaryAlbedo, "贴图2");
        if (enableSecondaryAlbedo.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(texBlendMode, "与贴图1的混合方式");
            m_MaterialEditor.TexturePropertySingleLine(Styles.secondaryAlbedoText, albedoMapSecondary);
            m_MaterialEditor.TextureScaleOffsetProperty(albedoMapSecondary);
        }
    }

    void DoDistortArea(Material material)
    {
        m_MaterialEditor.ShaderProperty(distort, Styles.enableDistortText);

        if (distort.floatValue != 0)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.distortText, distortMap);
            m_MaterialEditor.TextureScaleOffsetProperty(distortMap);
            m_MaterialEditor.TexturePropertySingleLine(Styles.distortText, secondaryDistortMap);
            m_MaterialEditor.TextureScaleOffsetProperty(secondaryDistortMap);
            m_MaterialEditor.ShaderProperty(distortFactor, "扰乱强度");
            m_MaterialEditor.VectorProperty(distortAni, "UV动画 XY贴图1 ZW贴图2");
        }
    }

    void DoMaskArea(Material material)
    {
        m_MaterialEditor.ShaderProperty(mask, Styles.enableMaskText);

        if (mask.floatValue != 0)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.maskText, maskMap);
            m_MaterialEditor.TextureScaleOffsetProperty(maskMap);
        }
    }

    void DoRimArea(Material material)
    {
        m_MaterialEditor.ShaderProperty(rim, Styles.enableRimText);

        if (rim.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(rimColor, "颜色");
            m_MaterialEditor.ShaderProperty(rimPower, "范围");
            Color rimCol = rimColor.colorValue;
            rimCol.a = rimPower.floatValue;
            rimColor.colorValue = rimCol;
        }
    }

    void DoDissolveArea(Material material)
    {
        m_MaterialEditor.ShaderProperty(dissolve, Styles.enableDissolveText);

        if (dissolve.floatValue != 0)
        {
            m_MaterialEditor.ShaderProperty(dissolveMode, "边缘方式");
            m_MaterialEditor.TexturePropertySingleLine(Styles.dissolveText, dissolveMap);
            m_MaterialEditor.TextureScaleOffsetProperty(dissolveMap);
            m_MaterialEditor.ShaderProperty(dissolveFactor, "溶解强度");
            m_MaterialEditor.ShaderProperty(dissolveEdge, "边缘宽度");
            if (dissolveMode.floatValue == 1)
            {
                m_MaterialEditor.ShaderProperty(dissolveSoft, "边缘硬度");
            }
            m_MaterialEditor.ShaderProperty(dissolveEdgeColor, "边缘颜色");
        }
    }
}