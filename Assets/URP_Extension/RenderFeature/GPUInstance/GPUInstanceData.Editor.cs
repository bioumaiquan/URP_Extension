using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

#endif

public partial class GPUInstanceData
{
#if UNITY_EDITOR
    public bool bake;
    public float TileSize = 5;
    public Transform InstanceRoot;
    private GameObject[] m_GameObjects;

    private void Bake()
    {
        if (InstanceRoot == null)
            return;

        int totalCount = InstanceRoot.childCount;
        if (totalCount == 0)
            return;

        InstanceRoot.gameObject.SetActive(true);
        m_GameObjects = GetGameObjectsForInstance(totalCount, out m_InstanceMesh, out m_InstanceMaterial);


        List<InstanceTile> tileList = new List<InstanceTile>();
        Vector3 tilePosition = Vector3.zero;
        float halfSize = TileSize * 0.5f;
        Vector3 boundSize = new Vector3(TileSize, TileSize, TileSize);
        List<Matrix4x4> matrix4X4s = new List<Matrix4x4>();

        // 获取一个包围所有物体的立方体
        // 这里只取了物体的坐标原点  适合小物体
        // 大物体的话需要检测物体包围盒
        Vector3 min, max;
        CalculateMinMaxPosition(m_GameObjects, out min, out max);

        //在立方体范围内生成格子
        int BoxCountX = Mathf.CeilToInt((max.x - min.x) / TileSize);
        int BoxCountY = Mathf.Max(1, Mathf.CeilToInt((max.y - min.y) / TileSize));
        int BoxCountZ = Mathf.CeilToInt((max.z - min.z) / TileSize);

        for (int x = 0; x < BoxCountX; x++)
        {
            tilePosition.x = min.x + halfSize + x * TileSize;
            for (int y = 0; y < BoxCountY; y++)
            {
                tilePosition.y = min.y + halfSize + y * TileSize;
                for (int z = 0; z < BoxCountZ; z++)
                {
                    tilePosition.z = min.z + halfSize + z * TileSize;

                    InstanceTile tile = new InstanceTile();
                    tile.bounds = new Bounds(tilePosition, boundSize);

                    matrix4X4s.Clear();
                    // 遍历所有物体 塞进对应的tile里
                    for (int i = 0; i < totalCount; i++)
                    {
                        Vector3 pos = m_GameObjects[i].transform.position;

                        if (tile.bounds.Contains(pos))
                        {
                            matrix4X4s.Add(m_GameObjects[i].transform.localToWorldMatrix);
                        }

                        if (i == totalCount - 1)
                        {
                            tile.localToWorld = new Matrix4x4[matrix4X4s.Count];

                            for (int j = 0; j < matrix4X4s.Count; j++)
                            {
                                tile.localToWorld[j] = matrix4X4s[j];
                            }

                            tile.batchCount = (matrix4X4s.Count / m_CountPerInstance) + 1;
                        }
                    }

                    if (tile.localToWorld.Length > 0) // 抛弃内部没有物体的tile
                        tileList.Add(tile);
                }
            }
        }

        // 生成格子数据
        int totalInstanceCount = 0;
        int maxInstanceCount = 0;
        int minInstanceCount = totalCount;
        m_InstanceTiles = new InstanceTile[tileList.Count];
        for (int i = 0; i < tileList.Count; i++)
        {
            m_InstanceTiles[i] = tileList[i];

            if (m_InstanceTiles[i].localToWorld.Length >= maxInstanceCount)
                maxInstanceCount = m_InstanceTiles[i].localToWorld.Length;

            if (m_InstanceTiles[i].localToWorld.Length <= minInstanceCount)
                minInstanceCount = m_InstanceTiles[i].localToWorld.Length;

            totalInstanceCount += m_InstanceTiles[i].localToWorld.Length;
        }

        int percentInstanceCount = totalInstanceCount / m_InstanceTiles.Length;
        Debug.LogError(String.Format("平均每格子内物体数量 : {0}, 最大格子内物体数量 : {1}, 最小格子内物体数量 : {2}", percentInstanceCount,
            maxInstanceCount, minInstanceCount));

        InstanceRoot.gameObject.SetActive(false);

        m_HasData = true;
    }

    GameObject[] GetGameObjectsForInstance(int totalCount, out Mesh instanceMesh, out Material instanceMaterial)
    {
        GameObject[] GOs = new GameObject[totalCount];
        for (int i = 0; i < totalCount; i++)
        {
            GOs[i] = InstanceRoot.GetChild(i).gameObject;
        }

        instanceMesh = GOs[0].GetComponent<MeshFilter>().sharedMesh;
        instanceMaterial = GOs[0].GetComponent<MeshRenderer>().sharedMaterial;
        instanceMaterial.enableInstancing = true;

        return GOs;
    }


    void CalculateMinMaxPosition(GameObject[] gos, out Vector3 minPos, out Vector3 maxPos)
    {
        Vector3 min = Vector3.zero;
        Vector3 max = Vector3.zero;
        for (int i = 0; i < gos.Length; i++)
        {
            Vector3 position = gos[i].transform.position;
            if (position.x < min.x)
                min.x = position.x;
            else if (position.x > max.x)
                max.x = position.x;

            if (position.y < min.y)
                min.y = position.y;
            else if (position.y > max.y)
                max.y = position.y;

            if (position.z < min.z)
                min.z = position.z;
            else if (position.z > max.z)
                max.z = position.z;
        }

        minPos = min;
        maxPos = max;
    }

    private void Update()
    {
        if (bake)
        {
            Bake();
            bake = false;
        }
    }

    public bool showTiles = false;

    private void OnDrawGizmos()
    {
        if (m_InstanceTiles == null)
            return;

        if (showTiles)
        {
            Gizmos.color = Color.green;
            for (int i = 0; i < m_InstanceTiles.Length; i++)
            {
                Gizmos.DrawWireCube(m_InstanceTiles[i].bounds.center, m_InstanceTiles[i].bounds.size);
            }
        }
    }


    [CustomEditor(typeof(GPUInstanceData))]
    public class GPUInstanceDataEditor : Editor
    {
        public static GUIContent bake = new GUIContent("烘焙");
        public static GUIContent TileSize = new GUIContent("格子大小");
        public static GUIContent InstanceRoot = new GUIContent("实例化根节点");
        public static GUIContent showTiles = new GUIContent("显示格子");
        public static GUIContent CastShadow = new GUIContent("产生阴影");
        
        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(serializedObject.FindProperty("bake"), bake);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("TileSize"), TileSize);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("InstanceRoot"), InstanceRoot);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("showTiles"), showTiles);
            EditorGUILayout.PropertyField(serializedObject.FindProperty("m_CastShadow"), CastShadow);

            serializedObject.ApplyModifiedProperties();
        }
    }
#endif
}