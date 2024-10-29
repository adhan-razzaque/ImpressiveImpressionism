using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class OutliningBlitRendererFeature : ScriptableRendererFeature
{
    public Shader m_Shader;

    public float colorThreshold = .2f;
    public float depthThreshold = .5f;
    public float maxDepth = 1f;
    public float outlineDimness = 0.5f;

    private Material m_Material;

    private OutliningBlitPass m_RenderPass = null;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game) return;

        renderer.EnqueuePass(m_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game) return;

        // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
        // ensures that the opaque texture is available to the Render Pass.
        m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color | ScriptableRenderPassInput.Depth);
        var settings = new OutliningBlitSettings
        {
            color_threshold = colorThreshold,
            depth_threshold = depthThreshold,
            max_depth = maxDepth,
            outline_dimness = outlineDimness,
        };
        m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, settings);
    }

    public override void Create()
    {
        if (m_Shader == null)
            m_Shader = Shader.Find("Custom/EdgeDetection");
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        m_RenderPass = new OutliningBlitPass(m_Material);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }
}