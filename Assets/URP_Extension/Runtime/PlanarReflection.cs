using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using IDs = BioumRP.ShaderPropertyIDs;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteAlways]
public class PlanarReflection : MonoBehaviour
{
    public enum TextureSize
    {
        small = 256,
        medium = 512,
        large = 1024,
    }
    public TextureSize userTextureSize = TextureSize.medium;
    int textureSize = 0;

    [Range(-2, 2)]
    public float Offset = 0.0f;
    [Range(0, 1)]
    public float transparent = 1;

    public LayerMask LayersToReflect = -1;

    private Camera reflectionCamera;
    private RenderTexture reflectionTexture = null;
    private static bool isRendering = false;
    private Material material;
    private Matrix4x4 reflectionMatrix;
    private Vector4 reflectionPlane;
    private Vector3 position;
    private Vector3 normal;
    private Matrix4x4 projection;
    private Vector4 oblique;
    private Matrix4x4 worldToCameraMatrix;
    private Vector3 clipNormal;
    private Vector4 clipPlane;
    private Vector3 lossyScale;
    private Vector3 oldPosition;
    Vector3 eulerAngles;
    RenderTextureFormat rtFormat = RenderTextureFormat.ARGB2101010;
    const string rtName = "_WaterReflection";

    void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += this.RenderObject;
        ShaderLevel.LevelChanged += SetWaterLevel;

        SetWaterLevel();

        if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGB2101010))
        {
            rtFormat = RenderTextureFormat.ARGB32;
        }

        material = GetComponent<Renderer>().sharedMaterials[0];

        var go = new GameObject(GetInstanceID().ToString(), typeof(Camera), typeof(Skybox));
        reflectionCamera = go.GetComponent<Camera>();
        var urpCameraData = go.AddComponent(typeof(UniversalAdditionalCameraData)) as UniversalAdditionalCameraData;
        urpCameraData.renderShadows = false;
        urpCameraData.requiresColorOption = CameraOverrideOption.Off;
        urpCameraData.requiresDepthOption = CameraOverrideOption.Off;
        reflectionCamera.enabled = false;
        reflectionCamera.transform.position = transform.position;
        reflectionCamera.transform.rotation = transform.rotation;

        go.hideFlags = HideFlags.HideAndDontSave;

        material.SetMaterialKeyword("_REFLECTION_TEXTURE", true);

        this.gameObject.layer = 4; // 设置为water 防止反射自身
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= this.RenderObject;
        ShaderLevel.LevelChanged -= SetWaterLevel;

        if (reflectionTexture)
        {
            RemoveObject(reflectionTexture);
            reflectionTexture = null;
        }
        if (reflectionCamera)
        {
            RemoveObject(reflectionCamera.gameObject);
            reflectionCamera = null;
        }
        material.SetMaterialKeyword("_REFLECTION_TEXTURE", false);
        oldSize = 0;
    }

    void SetWaterLevel()
    {
        switch (ShaderLevel.CurrentLevel)
        {
            case ShaderLevel.Level.High:
                textureSize = (int) userTextureSize;
                break;
            case ShaderLevel.Level.Medium:
                textureSize = (int) userTextureSize >> 1;
                break;
            case ShaderLevel.Level.Low:
                textureSize = (int) userTextureSize >> 1;
                break;
        }
    }

    int oldSize = 0;
    void SetTextureSize(int textureSize)
    {
        if (oldSize != textureSize)
        {
            if (reflectionTexture != null)
            {
                RemoveObject(reflectionTexture);
            }

            reflectionTexture = new RenderTexture(textureSize, textureSize, 16, RenderTextureFormat.ARGB2101010)
            {
                isPowerOfTwo = true,
                hideFlags = HideFlags.DontSave,
                name = rtName,
            };

            oldSize = textureSize;
        }
    }

    void RenderObject(ScriptableRenderContext context, Camera cam)
    {
        if (isRendering)
        {
            return;
        }
        if (ShaderLevel.CurrentLevel != ShaderLevel.Level.High)
        {
            return;
        }

        isRendering = true;
        position = transform.position;
        normal = transform.up;

        SetTextureSize(textureSize);

        reflectionCamera.clearFlags = CameraClearFlags.SolidColor;
        reflectionCamera.backgroundColor = Color.clear;

        reflectionCamera.farClipPlane = cam.farClipPlane;
        reflectionCamera.nearClipPlane = cam.nearClipPlane;
        reflectionCamera.orthographic = cam.orthographic;
        reflectionCamera.fieldOfView = cam.fieldOfView;
        reflectionCamera.aspect = cam.aspect;
        reflectionCamera.orthographicSize = cam.orthographicSize;
        reflectionCamera.cullingMask = ~(1 << 4) & LayersToReflect.value;

        reflectionPlane = new Vector4(normal.x, normal.y, normal.z, -Vector3.Dot(normal, position) - Offset);

        reflectionMatrix.m00 = (1F - 2F * reflectionPlane[0] * reflectionPlane[0]);
        reflectionMatrix.m01 = (-2F * reflectionPlane[0] * reflectionPlane[1]);
        reflectionMatrix.m02 = (-2F * reflectionPlane[0] * reflectionPlane[2]);
        reflectionMatrix.m03 = (-2F * reflectionPlane[3] * reflectionPlane[0]);
        reflectionMatrix.m10 = (-2F * reflectionPlane[1] * reflectionPlane[0]);
        reflectionMatrix.m11 = (1F - 2F * reflectionPlane[1] * reflectionPlane[1]);
        reflectionMatrix.m12 = (-2F * reflectionPlane[1] * reflectionPlane[2]);
        reflectionMatrix.m13 = (-2F * reflectionPlane[3] * reflectionPlane[1]);
        reflectionMatrix.m20 = (-2F * reflectionPlane[2] * reflectionPlane[0]);
        reflectionMatrix.m21 = (-2F * reflectionPlane[2] * reflectionPlane[1]);
        reflectionMatrix.m22 = (1F - 2F * reflectionPlane[2] * reflectionPlane[2]);
        reflectionMatrix.m23 = (-2F * reflectionPlane[3] * reflectionPlane[2]);
        reflectionMatrix.m30 = 0F;
        reflectionMatrix.m31 = 0F;
        reflectionMatrix.m32 = 0F;
        reflectionMatrix.m33 = 1F;

        oldPosition = cam.transform.position;
        reflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflectionMatrix;

        worldToCameraMatrix = reflectionCamera.worldToCameraMatrix;
        clipNormal = worldToCameraMatrix.MultiplyVector(normal).normalized;
        clipPlane = new Vector4(clipNormal.x, clipNormal.y, clipNormal.z, -Vector3.Dot(worldToCameraMatrix.MultiplyPoint(position + normal * Offset), clipNormal));

        projection = cam.projectionMatrix;
        oblique = clipPlane * (2.0F / (Vector4.Dot(clipPlane, projection.inverse * new Vector4(sgn(clipPlane.x), sgn(clipPlane.y), 1.0f, 1.0f))));
        projection[2] = oblique.x - projection[3];
        projection[6] = oblique.y - projection[7];
        projection[10] = oblique.z - projection[11];
        projection[14] = oblique.w - projection[15];
        reflectionCamera.projectionMatrix = projection;
        reflectionCamera.targetTexture = reflectionTexture;

        GL.invertCulling = true;
        reflectionCamera.transform.position = reflectionMatrix.MultiplyPoint(oldPosition);
        eulerAngles = cam.transform.eulerAngles;
        reflectionCamera.transform.eulerAngles = new Vector3(0, eulerAngles.y, eulerAngles.z);

        if(!Application.isPlaying)
            UniversalRenderPipeline.RenderSingleCamera(context, reflectionCamera);

        reflectionCamera.transform.position = oldPosition;
        GL.invertCulling = false;
        material.SetTexture(IDs.Scene.reflectionTexture, reflectionTexture);
        material.SetFloat(IDs.Scene.reflectionTransparent, transparent);

        isRendering = false;
    }

    void RemoveObject(Object obj)
    {
        if (Application.isEditor)
        {
            DestroyImmediate(obj);
        }
        else
        {
            Destroy(obj);
        }
    }

    private static float sgn(float a)
    {
        return a > 0.0f ? 1.0f : a < 0.0f ? -1.0f : 0.0f;
    }

#if UNITY_EDITOR
#region 编辑器面板
    [CustomEditor(typeof(PlanarReflection))]
    public class PlanarReflectionEditor : Editor
    {
        static class Styles
        {
            public static GUIContent clipPlaneOffset = new GUIContent("倒影偏移");
            public static GUIContent reflIntensity = new GUIContent("反射透明度");
            public static GUIContent reflectLayers = new GUIContent("反射层");

            public static string[] texSizeNames = { "256", "512", "1024", };
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.Space();
            SerializedProperty texSize = serializedObject.FindProperty("userTextureSize");
            texSize.enumValueIndex = EditorGUILayout.Popup("反射贴图大小", texSize.enumValueIndex, Styles.texSizeNames);

            EditorGUILayout.PropertyField(serializedObject.FindProperty("Offset"), Styles.clipPlaneOffset);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("transparent"), Styles.reflIntensity);

            EditorGUILayout.PropertyField(serializedObject.FindProperty("LayersToReflect"), Styles.reflectLayers);

            serializedObject.ApplyModifiedProperties();
        }

    }
#endregion
#endif
}