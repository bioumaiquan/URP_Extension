using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

public class SSAO : ScriptableRendererFeature
{
    private Material m_Material;
    [SerializeField, HideInInspector] private Shader m_Shader = null;
    const string m_ShaderName = "Bioum/RenderFeature/SSAO";
    
    [System.Serializable]
    public class SSAOSetting
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        
        [Range(0, 10)]public float intensity = 3.0f;
        [Range(0, 0.5f)]public float radius = 0.035f;
        [Range(4, 8)] public int sampleCount = 6;
    }


    class SSAORenderPass : ScriptableRenderPass
    {
        const int downsample = 2;

        public Material SSAOMaterial;

        public float intensity;
        public float radius;
        public float sampleCount;
        
        string profilerTag;
        
        // Constants
        private const string k_SSAOTextureName = "_ScreenSpaceOcclusionTexture";
        private const string k_OrthographicCameraKeyword = "_ORTHOGRAPHIC";

        // Statics
        private static readonly int s_BaseMapID = Shader.PropertyToID("_BaseMap");
        private static readonly int s_SSAOParamsID = Shader.PropertyToID("_SSAOParams");
        private static readonly int s_SSAOTexture1ID = Shader.PropertyToID("_SSAO_OcclusionTexture1");
        private static readonly int s_SSAOTexture2ID = Shader.PropertyToID("_SSAO_OcclusionTexture2");
        private static readonly int s_SSAOTexture3ID = Shader.PropertyToID("_SSAO_OcclusionTexture3");
        
        private RenderTargetIdentifier m_SSAOTexture1Target = new RenderTargetIdentifier(s_SSAOTexture1ID);
        private RenderTargetIdentifier m_SSAOTexture2Target = new RenderTargetIdentifier(s_SSAOTexture2ID);
        private RenderTargetIdentifier m_SSAOTexture3Target = new RenderTargetIdentifier(s_SSAOTexture3ID);
        private RenderTextureDescriptor m_Descriptor;
        
        private RenderTargetIdentifier source { get; set; }

        public void Setup(RenderTargetIdentifier source) {
            this.source = source;
        }

        public SSAORenderPass(string profilerTag)
        {
            this.profilerTag = profilerTag;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            // Get temporary render textures
            m_Descriptor = cameraTextureDescriptor;
            m_Descriptor.msaaSamples = 1;
            //m_Descriptor.depthBufferBits = 0;
            m_Descriptor.colorFormat = RenderTextureFormat.ARGB32;
            m_Descriptor.width /= downsample;
            m_Descriptor.height /= downsample;
            cmd.GetTemporaryRT(s_SSAOTexture1ID, m_Descriptor, FilterMode.Bilinear);
            
            m_Descriptor.width *= downsample;
            m_Descriptor.height *= downsample;
            cmd.GetTemporaryRT(s_SSAOTexture2ID, m_Descriptor, FilterMode.Bilinear);
            cmd.GetTemporaryRT(s_SSAOTexture3ID, m_Descriptor, FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            RenderTextureDescriptor cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            
            // Update SSAO parameters in the material
            Vector4 ssaoParams = new Vector4(
                intensity,   // Intensity
                radius,      // Radius
                1.0f / downsample,      // Downsampling
                sampleCount  // Sample count
            );
            SSAOMaterial.SetVector(s_SSAOParamsID, ssaoParams);
            CoreUtils.SetKeyword(SSAOMaterial, k_OrthographicCameraKeyword, renderingData.cameraData.camera.orthographic);


            CommandBuffer cmd = CommandBufferPool.Get(profilerTag);

            SSAOMaterial.SetVector("_SourceSize",
                new Vector4(cameraTargetDescriptor.width, cameraTargetDescriptor.height, 1.0f / cameraTargetDescriptor.width, 1.0f / cameraTargetDescriptor.height));


            // Execute the SSAO
            Render(cmd, m_SSAOTexture1Target, ShaderPasses.AO);

            // Execute the Blur Passes
            RenderAndSetBaseMap(cmd, m_SSAOTexture1Target, m_SSAOTexture2Target, ShaderPasses.BlurHorizontal);
            RenderAndSetBaseMap(cmd, m_SSAOTexture2Target, m_SSAOTexture3Target, ShaderPasses.BlurVertical);
            //RenderAndSetBaseMap(cmd, m_SSAOTexture3Target, source, ShaderPasses.BlurFinal);

            Blit(cmd,m_SSAOTexture3Target, source, SSAOMaterial, 3);
            
            // Set the global SSAO texture
            //cmd.SetGlobalTexture(k_SSAOTextureName, m_SSAOTexture2Target);
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        
        private enum ShaderPasses
        {
            AO = 0,
            BlurHorizontal = 1,
            BlurVertical = 2,
            BlurFinal = 3,
        }
        
        private void Render(CommandBuffer cmd, RenderTargetIdentifier target, ShaderPasses pass)
        {
            cmd.SetRenderTarget(
                target,
                RenderBufferLoadAction.DontCare,
                RenderBufferStoreAction.Store,
                target,
                RenderBufferLoadAction.DontCare,
                RenderBufferStoreAction.DontCare
            );
            cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, SSAOMaterial, 0, (int) pass);
        }

        private void RenderAndSetBaseMap(CommandBuffer cmd, RenderTargetIdentifier baseMap, RenderTargetIdentifier target, ShaderPasses pass)
        {
            cmd.SetGlobalTexture(s_BaseMapID, baseMap);
            Render(cmd, target, pass);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }

    SSAORenderPass scriptablePass;
    public SSAOSetting settings = new SSAOSetting();

    public override void Create()
    {
        scriptablePass = new SSAORenderPass("SSAO");

        m_Shader = Shader.Find(m_ShaderName);
        if(!m_Material)
            m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        scriptablePass.SSAOMaterial = m_Material;
        
        scriptablePass.intensity = settings.intensity;
        scriptablePass.radius = settings.radius;
        scriptablePass.sampleCount = settings.sampleCount;

        scriptablePass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        scriptablePass.Setup(src);
        renderer.EnqueuePass(scriptablePass);
    }
}


