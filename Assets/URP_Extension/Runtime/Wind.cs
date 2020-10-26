using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Wind : MonoBehaviour
{
    public float directionX = 0;
    public float directionY = 0;
    public float speed = 0;
    public float scale = 0;
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("g_WindParam", new Vector4(directionX, directionY, speed, scale));
    }
}