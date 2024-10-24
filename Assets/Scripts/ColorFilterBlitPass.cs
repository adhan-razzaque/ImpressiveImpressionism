using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public struct ColorFilterBlitSettings
{
    public float red_orange;
    public float yellow_green;
    public float violet_fuschia;
    public float blue_indigo;

    public float add_red;
    public float add_green;
    public float add_blue;
}


internal class ColorFilterBlitPass : ScriptableRenderPass
{
    private ProfilingSampler m_ProfilingSampler = new("ColorFilterBlit");
    private Material m_Material;
    private RTHandle m_CameraColorTarget;

    private ColorFilterBlitSettings _settings;


    public ColorFilterBlitPass(Material material)
    {
        m_Material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public void SetTarget(RTHandle colorHandle, ColorFilterBlitSettings settings)
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
            m_Material.SetFloat("red_orange", _settings.red_orange);
            m_Material.SetFloat("yellow_green", _settings.yellow_green);
            m_Material.SetFloat("violet_fuschia", _settings.violet_fuschia);
            m_Material.SetFloat("blue_indigo", _settings.blue_indigo);
            m_Material.SetFloat("add_red", _settings.add_red);
            m_Material.SetFloat("add_green", _settings.add_green);
            m_Material.SetFloat("add_blue", _settings.add_blue);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}