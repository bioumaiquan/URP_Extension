using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CreateGameObject : MonoBehaviour
{
    public float range = 20;
    public int createGameObjectsCount = 2000;
    public bool createGameObjects = false;
    
    public GameObject gameObjectForInstance;
    
    public bool removeGameObjects = false;
    public GameObject[] gos;

    
    

    void Update()
    {
        if (createGameObjects)
        {
            CreateGameObjects();
            createGameObjects = false;
        }

        if (removeGameObjects)
        {
            for (int i = 0; i < createGameObjectsCount; i++)
            {
                DestroyImmediate(gos[i]);
            }

            removeGameObjects = false;
        }
    }
    
    
    void CreateGameObjects()
    {
        if (gameObjectForInstance != null)
        {
            gos = new GameObject[createGameObjectsCount];
            Vector3 pos = Vector3.zero;
            Vector3 rot = Vector3.zero;
            for (int i = 0; i < createGameObjectsCount; i++)
            {
                pos = GetRandomPosition();

                rot.y = Random.Range(0.0f, 360.0f);

                gos[i] = Instantiate(gameObjectForInstance, pos, Quaternion.Euler(rot), this.transform);
                
                
                float s = Random.Range(1, 1.5f);
                Vector3 scale = new Vector3(s, s, s);
                gos[i].transform.localScale = scale;
            }
        }
    }

    private const float TWO_PI = Mathf.PI * 2;
    Vector3 GetRandomPosition()
    {
        float theta = Random.value * TWO_PI;
        
        float k = Random.value;
        float r = Mathf.Sqrt(k) * range;
        
        float x = Mathf.Sin(theta) * r;
        float y = Random.Range(0, 10) * (1 - k);
        float z = Mathf.Cos(theta) * r;
        
        Vector3 pos = new Vector3(x, y, z);
        
        return pos;
    }
}
