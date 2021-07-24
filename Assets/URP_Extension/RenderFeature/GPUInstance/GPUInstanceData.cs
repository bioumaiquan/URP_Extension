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
        public Matrix4x4[] localToWorld;
        public int batchCount;
        public Bounds bounds;
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

    public int createGameObjectsCount = 2000;
    public bool createGameObjects = false;
    public GameObject gameObjectForInstance;

    
    private void OnEnable()
    {
        Instance = this;
    }

    public float TileSize = 5;
    
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
        int BoxCountX = (int)((minMaxPos.z - minMaxPos.x) / TileSize) + 1;
        int BoxCountZ = (int)((minMaxPos.w - minMaxPos.y) / TileSize) + 1;
        
        // GameObject box = new GameObject("box");
        // box.AddComponent<BoxCollider>();
        // box.transform.localScale = Vector3.one * TileSize;
        
        List<InstanceTile> tileList = new List<InstanceTile>();
        Vector3 tilePosition = Vector3.zero;
        float halfSize = TileSize * 0.5f;
        Vector3 boundSize = Vector3.one * TileSize;
        List<Matrix4x4> matrix4X4s = new List<Matrix4x4>();
        
        for (int i = 0; i < BoxCountX; i++)
        {
            tilePosition.x = minMaxPos.x + halfSize + i * TileSize;
            for (int j = 0; j < BoxCountZ; j++)
            {
                tilePosition.z = minMaxPos.y + halfSize + j * TileSize;
                //GameObject go = GameObject.Instantiate(box, tilePosition, Quaternion.identity);

                InstanceTile tile = new InstanceTile();
                tile.bounds = new Bounds(tilePosition, boundSize);
                
                matrix4X4s.Clear();
                for (int k = 0; k < totalCount; k++) // 遍历所有物体 塞进对应的tile里
                {
                    Transform trans = transform.GetChild(k);
                    Vector3 pos = trans.position;
                    
                    if (pos.x > tile.bounds.min.x &&
                        pos.x < tile.bounds.max.x &&
                        pos.z > tile.bounds.min.z &&
                        pos.z < tile.bounds.max.z
                    )
                    {
                        matrix4X4s.Add(trans.localToWorldMatrix);
                    }
                    
                    if (k == totalCount - 1)
                    {
                        tile.localToWorld = new Matrix4x4[matrix4X4s.Count];

                        for (int l = 0; l < matrix4X4s.Count; l++)
                        {
                            tile.localToWorld[l] = matrix4X4s[l];
                        }

                        tile.batchCount = (matrix4X4s.Count / CountPerInstance) + 1;
                    }
                }
                
                if(tile.localToWorld.Length > 0) // 抛弃内部没有物体的tile
                    tileList.Add(tile);
            }
        }

        m_InstanceTiles = new InstanceTile[tileList.Count];
        for (int i = 0; i < tileList.Count; i++)
        {
            m_InstanceTiles[i] = tileList[i];
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

    void CreateGameObjects()
    {
        if (gameObjectForInstance != null)
        {
            Vector3 pos = Vector3.zero;
            Vector3 rot = Vector3.zero;
            for (int i = 0; i < createGameObjectsCount; i++)
            {
                pos.x = Random.Range(-20.0f, 20.0f);
                pos.z = Random.Range(-20.0f, 20.0f);

                rot.y = Random.Range(0.0f, 360.0f);
                
                GameObject.Instantiate(gameObjectForInstance, pos, Quaternion.Euler(rot), this.transform);
            }
        }
    }

    private void Update()
    {
        if (bake)
        {
            Bake();
            bake = false;
        }

        if (createGameObjects)
        {
            CreateGameObjects();
            createGameObjects = false;
        }
    }
}
