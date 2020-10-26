using System.Collections;
using System.Collections.Generic;
using BioumRP;
using UnityEngine;

[ExecuteAlways]
public class SceneNoise : MonoBehaviour
{
    [SerializeField]
    float _noiseAmplitude = 0.05f;

    [SerializeField]
    float _noiseFrequency = 1.0f;

    [SerializeField]
    float speed = 0.2f;

    float _noiseOffset;
    Vector3 noiseParam = Vector3.zero;

    void Update()
    {
        _noiseOffset += speed * Time.deltaTime;

        noiseParam.x = _noiseAmplitude;
        noiseParam.y = _noiseFrequency;
        noiseParam.z = _noiseOffset;
        Shader.SetGlobalVector(ShaderPropertyIDs.Scene.noiseParam, noiseParam);
    }
}