using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

public class GPUInstanceRenderFeature : ScriptableRendererFeature
{
    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    
    GPUInstanceRenderPass scriptablePass;
    public override void Create()
    {
        scriptablePass = new GPUInstanceRenderPass("GPU Instance");
        scriptablePass.renderPassEvent = renderPassEvent;
        scriptablePass.localToWorldList = new List<Matrix4x4[]>();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(scriptablePass);
    }


    class GPUInstanceRenderPass : ScriptableRenderPass
    {
        string profilerTag;
        public List<Matrix4x4[]> localToWorldList;
        
        public GPUInstanceRenderPass(string profilerTag)
        {
            this.profilerTag = profilerTag;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            Camera camera = renderingData.cameraData.camera;
            if (camera.cameraType != CameraType.Game && camera.cameraType != CameraType.SceneView)
                return;
            
            GPUInstanceData.InstanceTile[] tiles = GPUInstanceData.Instance.InstanceTiles;

            if (tiles == null)
                return;
            
            Material instanceMaterial = GPUInstanceData.Instance.InstanceMaterial;
            Mesh instanceMesh = GPUInstanceData.Instance.InstanceMesh;
            int countPerInstance = GPUInstanceData.Instance.CountPerInstance;
            

            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

            
            for (int i = 0; i < tiles.Length; i++)
            {
                int totalCount = tiles[i].localToWorld.Length;

                if (tiles[i].BatchCount == 1)
                {
                    cmd.DrawMeshInstanced(instanceMesh, 0, instanceMaterial, 0, tiles[i].localToWorld);
                }
                else
                {
                    localToWorldList.Clear();
                    
                    //tile内的总mesh数量可能大于合批数量  所以先拆分数组
                    
                    //前几批的数组
                    int j;
                    for (j = 0; j < tiles[i].BatchCount - 1; j++)
                    {
                        Matrix4x4[] matrix4x4s = new Matrix4x4[countPerInstance];
                        Array.Copy(tiles[i].localToWorld, j * countPerInstance, matrix4x4s, 0, countPerInstance);
                        localToWorldList.Add(matrix4x4s);
                    }
                    
                    //最后一个批次的矩阵数组
                    int lastCount = totalCount - (tiles[i].BatchCount - 1) * countPerInstance;
                    if (lastCount > 0)
                    {
                        Matrix4x4[] lastMatrix4x4s = new Matrix4x4[lastCount];
                        Array.Copy(tiles[i].localToWorld, j * countPerInstance, lastMatrix4x4s, 0, lastCount);
                        localToWorldList.Add(lastMatrix4x4s);
                    }

                    //渲染
                    for (int k = 0; k < localToWorldList.Count; k++)
                    {
                        cmd.DrawMeshInstanced(instanceMesh, 0, instanceMaterial, 0, localToWorldList[k]);
                    }
                }
            }


            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
}