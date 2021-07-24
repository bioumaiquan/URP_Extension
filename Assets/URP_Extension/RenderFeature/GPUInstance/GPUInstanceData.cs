using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;

[ExecuteAlways]
public class GPUInstanceData : MonoBehaviour
{
    [Serializable]
    public class InstanceTile
    {
        public Vector4 tileMinMax;
        public Matrix4x4[] localToWorld;
        public int BatchCount = 1;
    }

    [SerializeField] private InstanceTile[] m_InstanceTiles;
    public InstanceTile[] InstanceTiles => m_InstanceTiles;

    [SerializeField] private Material m_InstanceMaterial;
    public Material InstanceMaterial => m_InstanceMaterial;
    
    [SerializeField] private Mesh m_InstanceMesh;
    public Mesh InstanceMesh => m_InstanceMesh;
    
    [SerializeField] private int m_CountPerInstance = 500;
    public int CountPerInstance => m_CountPerInstance;
    
    
    public static GPUInstanceData Instance;
    public bool bake;

    
    private void OnEnable()
    {
        Instance = this;
    }

    private int BoxSize = 5;
    
    private void Bake()
    {
        int totalCount = transform.childCount;
        if (totalCount == 0)
            return;
        
        for (int k = 0; k < totalCount; k++)
        {
            transform.GetChild(k).gameObject.SetActive(true);
        }

        GameObject instanceGO = transform.GetChild(0).gameObject;
        m_InstanceMesh = instanceGO.GetComponent<MeshFilter>().sharedMesh;
        m_InstanceMaterial = instanceGO.GetComponent<MeshRenderer>().sharedMaterial;
        

        Vector4 minMaxPos = CalculateMinMaxPosition(transform);
        int BoxCountX = (int)(minMaxPos.z - minMaxPos.x) / BoxSize + 1;
        int BoxCountZ = (int)(minMaxPos.w - minMaxPos.y) / BoxSize + 1;

        GameObject box = new GameObject("box");
        box.AddComponent<BoxCollider>();
        box.transform.localScale = Vector3.one * BoxSize;

        m_InstanceTiles = new InstanceTile[BoxCountX * BoxCountZ];
        Vector3 pos = Vector3.zero;
        for (int i = 0; i < BoxCountX; i++)
        {
            pos.x = minMaxPos.x + BoxSize * 0.5f + i * BoxSize;
            for (int j = 0; j < BoxCountZ; j++)
            {
                pos.z = minMaxPos.y + BoxSize * 0.5f + j * BoxSize;
                GameObject.Instantiate(box, pos, Quaternion.identity);
            }
        }
        

        for (int k = 0; k < totalCount; k++)
        {
            transform.GetChild(k).gameObject.SetActive(false);
        }
    }
    
    
    Vector4 CalculateMinMaxPosition(Transform transform)
    {
        Vector4 MinMaxPosition = Vector4.zero;
        int maxCount = transform.childCount;
        for (int i = 0; i < maxCount; i++)
        {
            Vector3 position = transform.GetChild(i).position;
            if (position.x < MinMaxPosition.x)
                MinMaxPosition.x = position.x;
            else if (position.x > MinMaxPosition.z)
                MinMaxPosition.z = position.x;
            
            if (position.z < MinMaxPosition.y)
                MinMaxPosition.y = position.z;
            else if (position.z > MinMaxPosition.w)
                MinMaxPosition.w = position.z;
        }

        return MinMaxPosition;
    }

    private void Update()
    {
        if (bake)
        {
            Bake();
            bake = false;
        }
    }
}
