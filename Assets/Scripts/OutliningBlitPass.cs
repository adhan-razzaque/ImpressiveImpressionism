using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public struct OutliningBlitSettings
{
    public float color_threshold;
    public float depth_threshold;
    public float max_depth;
    public float outline_dimness;
}


internal class OutliningBlitPass : ScriptableRenderPass
{
    private ProfilingSampler m_ProfilingSampler = new("OutliningBlit");
    private Material m_Material;
    private RTHandle m_CameraColorTarget;

    private OutliningBlitSettings _settings;

    private static readonly int ColorThreshold = Shader.PropertyToID("color_threshold");
    private static readonly int DepthThreshold = Shader.PropertyToID("depth_threshold");
    private static readonly int MaxDepth = Shader.PropertyToID("max_depth");
    private static readonly int OutlineDimness = Shader.PropertyToID("outline_dimness");

    public OutliningBlitPass(Material material)
    {
        m_Material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public void SetTarget(RTHandle colorHandle, OutliningBlitSettings settings)
    {
        m_CameraColorTarget = colorHandle;
        _settings = settings;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureTarget(m_CameraColorTarget);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.camera.cameraType != CameraType.Game)
            return;

        if (m_Material == null)
            return;

        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            m_Material.SetFloat(ColorThreshold, _settings.color_threshold);
            m_Material.SetFloat(DepthThreshold, _settings.depth_threshold);
            m_Material.SetFloat(MaxDepth, _settings.max_depth);
            m_Material.SetFloat(OutlineDimness, _settings.outline_dimness);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}