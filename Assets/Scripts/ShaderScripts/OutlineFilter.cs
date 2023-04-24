using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OutlineFilter : MonoBehaviour
{
    public Shader outlineShader;

    /* properties */    
    [Header("Edge Detection")]
    public bool enableOutlining = true;
    [Range(0.0f, 25.0f)] public float colorThreshold = 0.20f;    /* gradient's Threshold  to define edges based on color */
    [Range(0.0f, 25.0f)] public float depthThreshold = 0.50f;    /* gradient's threshold to define edges based on depth  */
    [Range(0.0f, 1.0f)] public float maxDepth = 1.0f;          /* max depth of the scene where 0 = camera location, 1 = rear clipping plane*/

    /* define shader's properties */
    private readonly int enableOutlining_id = Shader.PropertyToID("_enableOutlining");
    private readonly int colorThreshold_id = Shader.PropertyToID("_colorThreshold");
    private readonly int depthThreshold_id = Shader.PropertyToID("_depthThreshold");
    private readonly int maxDepth_id = Shader.PropertyToID("_maxDepth");


    private Material postprocessMaterial;

    private void Start() {
        if (outlineShader == null) {
            Debug.LogError("No Edge Detection Shader");
            return;
        }

        postprocessMaterial = new Material(outlineShader);

        Camera cam = GetComponent<Camera>();
        cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {

        if(postprocessMaterial == null) {
            Debug.LogError("No Edge Detection Shader");
            return;
        }

        /* set properties */
        postprocessMaterial.SetInt(enableOutlining_id, enableOutlining ? 1 : 0);
        postprocessMaterial.SetFloat(colorThreshold_id, colorThreshold);
        postprocessMaterial.SetFloat(depthThreshold_id, depthThreshold);
        postprocessMaterial.SetFloat(maxDepth_id, maxDepth);

        Graphics.Blit(source, destination, postprocessMaterial);
    }
}
