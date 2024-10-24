using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class ColorFilterBlitRendererFeature : ScriptableRendererFeature
{
    public Shader m_Shader;

    public float redOrange = 0.55f;
    public float yellowGreen = 0.8f;
    public float blueIndigo = 0.7f;
    public float violetFuschia = 0.4f;

    public float addRed;
    public float addGreen;
    public float addBlue;

    private Material m_Material;

    private ColorFilterBlitPass m_RenderPass = null;

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
        m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
        var settings = new ColorFilterBlitSettings
        {
            RedOrange = redOrange,
            YellowGreen = yellowGreen,
            VioletFuschia = violetFuschia,
            BlueIndigo = blueIndigo,

            AddRed = addRed,
            AddGreen = addGreen,
            AddBlue = addBlue,
        };
        m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, settings);
    }

    public override void Create()
    {
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        m_RenderPass = new ColorFilterBlitPass(m_Material);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }
}