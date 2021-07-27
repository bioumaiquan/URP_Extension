using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public partial class GPUInstanceData : MonoBehaviour
{
    [Serializable]
    public struct InstanceTile
    {
        public Matrix4x4[] localToWorld;
        public int batchCount;
        public Bounds bounds;
    }

    [HideInInspector] [SerializeField] private InstanceTile[] m_InstanceTiles;
    public InstanceTile[] InstanceTiles => m_InstanceTiles;

    [HideInInspector] [SerializeField] private Material m_InstanceMaterial;
    public Material InstanceMaterial => m_InstanceMaterial;

    [HideInInspector] [SerializeField] private Mesh m_InstanceMesh;
    public Mesh InstanceMesh => m_InstanceMesh;

    [HideInInspector] [SerializeField] private bool m_HasData;
    public bool HasData => m_HasData;
    
    [HideInInspector] [SerializeField] private bool m_CastShadow;
    public bool CastShadow => m_CastShadow;

    // GrawMeshInstanced API限制每批次最多1023个物体 
    // 但是受限于平台的常量缓冲区大小 这个值达不到最大  
    // unity默认限制为 安卓平台250 其他500
    // https://github.com/vanCopper/Unity-GPU-Instancing
    private int m_CountPerInstance = 1000;
    public int CountPerInstance => m_CountPerInstance;

    public static GPUInstanceData Instance; //全局唯一 便于render feature调用

    private void OnEnable()
    {
        Instance = this;
        this.gameObject.name = "GPU Instanced Data";
    }

    private void OnDisable()
    {
        Instance = null;
    }
}