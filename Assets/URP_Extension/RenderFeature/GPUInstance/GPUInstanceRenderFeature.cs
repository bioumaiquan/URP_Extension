using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

public class GPUInstanceRenderFeature : ScriptableRendererFeature
{
    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    public bool renderingShadows = true;
    
    GPUInstanceRenderPass RenderingPass;
    GPUInstanceShadowPass ShadowPass;
    public override void Create()
    {
        Render render = new Render();
        
        RenderingPass = new GPUInstanceRenderPass("GPU Instance Rendering");
        RenderingPass.renderPassEvent = renderPassEvent;
        RenderingPass.m_Render = render;

        if (renderingShadows)
        {
            ShadowPass = new GPUInstanceShadowPass("GPU Instance Shadow");
            ShadowPass.renderPassEvent = RenderPassEvent.AfterRenderingShadows;
            ShadowPass.m_Render = render;
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(RenderingPass);
        
        if(renderingShadows)
            renderer.EnqueuePass(ShadowPass);
    }

    public class Render
    {
        public struct TileData
        {
            public Bounds bounds;
            public List<Matrix4x4[]> matrix4X4sList;
        }
        private TileData[] TileDatas;
        private Mesh instanceMesh;
        private Material instanceMaterial;
        private Plane[] frustumPlanes = new Plane[6];
        private bool castShadow;
        
        private int lastInstanceID = 0;
        private bool InitData(GPUInstanceData instanceData)
        {
            if (instanceData == null || !instanceData.HasData)
            {
                lastInstanceID = 0;
                return false;
            }
            
            if (lastInstanceID == instanceData.GetInstanceID())
                return true;
            
            lastInstanceID = instanceData.GetInstanceID();

            GPUInstanceData.InstanceTile[] tiles = instanceData.InstanceTiles;
            int countPerInstance = instanceData.CountPerInstance;
            instanceMaterial = instanceData.InstanceMaterial;
            instanceMesh = instanceData.InstanceMesh;
            castShadow = instanceData.CastShadow;
            
            TileDatas = new TileData[tiles.Length];
            for (int i = 0; i < TileDatas.Length; i++)
            {
                TileDatas[i].bounds = tiles[i].bounds;
                TileDatas[i].matrix4X4sList = new List<Matrix4x4[]>();

                if (tiles[i].batchCount == 1)
                {
                    TileDatas[i].matrix4X4sList.Add(tiles[i].localToWorld);
                }
                else
                {
                    //tile内的总mesh数量可能大于合批数量  所以先拆分数组
                    //在这里拆分而不是烘焙时拆分是因为 List<Matrix4x4[]> 无法序列化
                    
                    //前几批的数组
                    int j;
                    for (j = 0; j < tiles[i].batchCount - 1; j++)
                    {
                        Matrix4x4[] matrix4x4s = new Matrix4x4[countPerInstance];
                        Array.Copy(tiles[i].localToWorld, j * countPerInstance, matrix4x4s, 0, countPerInstance);
                        TileDatas[i].matrix4X4sList.Add(matrix4x4s);
                    }
                    
                    //最后一个批次的矩阵数组
                    int totalCount = tiles[i].localToWorld.Length;
                    int lastCount = totalCount - (tiles[i].batchCount - 1) * countPerInstance;
                    if (lastCount > 0)
                    {
                        Matrix4x4[] lastMatrix4x4s = new Matrix4x4[lastCount];
                        Array.Copy(tiles[i].localToWorld, j * countPerInstance, lastMatrix4x4s, 0, lastCount);
                        TileDatas[i].matrix4X4sList.Add(lastMatrix4x4s);
                    }
                }
            }

            return true;
        }
        
        public void Execute(CommandBuffer cmd, ref RenderingData renderingData, string passName, bool isShadowPass)
        {
            if (renderingData.cameraData.cameraType != CameraType.Game && 
                renderingData.cameraData.cameraType != CameraType.SceneView)
                return;

            if (isShadowPass && (!renderingData.shadowData.supportsMainLightShadows))
                return;
            
            bool hasData = InitData(GPUInstanceData.Instance);

            if (!hasData)
                return;

            if (isShadowPass && !castShadow)
                return;
            
            int passID = instanceMaterial.FindPass(passName);
            
            //获取相机视锥体的平面 用于剔除
            GeometryUtility.CalculateFrustumPlanes(renderingData.cameraData.camera, frustumPlanes);

            // 对每个格子进行实例化绘制
            for (int i = 0; i < TileDatas.Length; i++)
            {
                // 视锥体剔除
                //TODO : 四叉树剔除
                bool inView = GeometryUtility.TestPlanesAABB(frustumPlanes, TileDatas[i].bounds);
                if(!inView)
                    continue;
                
                //渲染
                for (int j = 0; j < TileDatas[i].matrix4X4sList.Count; j++)
                {
                    cmd.DrawMeshInstanced(instanceMesh, 0, instanceMaterial, passID, TileDatas[i].matrix4X4sList[j]);
                }
            }
        }
    }


    class GPUInstanceShadowPass : ScriptableRenderPass
    {
        string profilerTag;
        public Render m_Render;
        private string passName = "ShadowCaster";
        
        public GPUInstanceShadowPass(string profilerTag)
        {
            this.profilerTag = profilerTag;
        }
        
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);
            m_Render.Execute(cmd, ref renderingData, passName, true);
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
        
    }


    class GPUInstanceRenderPass : ScriptableRenderPass
    {
        string profilerTag;
        public Render m_Render;
        private string passName = "ForwardLit";
        
        public GPUInstanceRenderPass(string profilerTag)
        {
            this.profilerTag = profilerTag;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);
            m_Render.Execute(cmd, ref renderingData, passName, false);
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }
}