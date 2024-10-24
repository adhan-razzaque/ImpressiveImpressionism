using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public struct ColorFilterBlitSettings
{
    public float RedOrange;
    public float YellowGreen;
    public float VioletFuschia;
    public float BlueIndigo;

    public float AddRed;
    public float AddGreen;
    public float AddBlue;
}


internal class ColorFilterBlitPass : ScriptableRenderPass
{
    private ProfilingSampler m_ProfilingSampler = new("ColorFilterBlit");
    private Material m_Material;
    private RTHandle m_CameraColorTarget;

    private ColorFilterBlitSettings _settings;

    private static readonly int RedOrange = Shader.PropertyToID("red_orange");
    private static readonly int YellowGreen = Shader.PropertyToID("yellow_green");
    private static readonly int VioletFuschia = Shader.PropertyToID("violet_fuschia");
    private static readonly int BlueIndigo = Shader.PropertyToID("blue_indigo");
    private static readonly int AddRed = Shader.PropertyToID("add_red");
    private static readonly int AddGreen = Shader.PropertyToID("add_green");
    private static readonly int AddBlue = Shader.PropertyToID("add_blue");

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
            m_Material.SetFloat(RedOrange, _settings.RedOrange);
            m_Material.SetFloat(YellowGreen, _settings.YellowGreen);
            m_Material.SetFloat(VioletFuschia, _settings.VioletFuschia);
            m_Material.SetFloat(BlueIndigo, _settings.BlueIndigo);
            m_Material.SetFloat(AddRed, _settings.AddRed);
            m_Material.SetFloat(AddGreen, _settings.AddGreen);
            m_Material.SetFloat(AddBlue, _settings.AddBlue);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}