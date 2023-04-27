using System;
using UnityEngine;

namespace ShaderScripts
{
    public class OilPaintingEffect : MonoBehaviour
    {
        public Shader kuwaharaShader;
        public Shader edgeFlowShader;
        public Shader compositorShader;

        public Settings settings;

        // Materials
        private Material _kuwaharaMaterial;
        private Material _edgeFlowMaterial;
        private Material _compositorMaterial;

        // Cached properties
        private static readonly int KernelSize = Shader.PropertyToID("kernel_size");
        private static readonly int Sharpness = Shader.PropertyToID("sharpness");
        private static readonly int Hardness = Shader.PropertyToID("hardness");
        private static readonly int Alpha = Shader.PropertyToID("alpha");
        private static readonly int ZeroCrossing = Shader.PropertyToID("zero_crossing");
        private static readonly int Zeta = Shader.PropertyToID("zeta");
        private static readonly int N = Shader.PropertyToID("n");
        private static readonly int Tfm = Shader.PropertyToID("tfm");
        private static readonly int NoiseTex = Shader.PropertyToID("_NoiseTex");
        private static readonly int StreamLineLength = Shader.PropertyToID("_StreamLineLength");
        private static readonly int StreamKernelStrength = Shader.PropertyToID("_StreamKernelStrength");
        private static readonly int EdgeContribution = Shader.PropertyToID("_EdgeContribution");
        private static readonly int FlowContribution = Shader.PropertyToID("_FlowContribution");
        private static readonly int DepthContribution = Shader.PropertyToID("_DepthContribution");
        private static readonly int BumpPower = Shader.PropertyToID("_BumpPower");
        private static readonly int BumpIntensity = Shader.PropertyToID("_BumpIntensity");
        private static readonly int EdgeFlowTex = Shader.PropertyToID("_EdgeFlowTex");

        // Unity Messages
        private void Start()
        {
            var cam = GetComponent<Camera>();

            if (!cam)
            {
                Debug.LogWarning("Could not find Camera Component");
                return;
            }

            cam.depthTextureMode |= DepthTextureMode.Depth;
        }

        private void OnEnable()
        {
            if (compositorShader == null || kuwaharaShader == null || edgeFlowShader == null)
            {
                Debug.LogError("Missing shaders");
                return;
            }

            _kuwaharaMaterial = new Material(kuwaharaShader)
            {
                // Leave destruction up to this script
                hideFlags = HideFlags.HideAndDontSave
            };
            _edgeFlowMaterial = new Material(edgeFlowShader)
            {
                // Leave destruction up to this script
                hideFlags = HideFlags.HideAndDontSave
            };
            _compositorMaterial = new Material(compositorShader)
            {
                // Leave destruction up to this script
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        private void OnDisable()
        {
            _kuwaharaMaterial = null;
            _edgeFlowMaterial = null;
            _compositorMaterial = null;
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (compositorShader == null || kuwaharaShader == null || edgeFlowShader == null) return;

            // Set properties
            Setup();
            
            // Get structure tensor to run kuwahara
            var structureTensor = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(source, structureTensor, _kuwaharaMaterial, 0);
            var eigenvectors1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(structureTensor, eigenvectors1, _kuwaharaMaterial, 1);
            var eigenvectors2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(eigenvectors1, eigenvectors2, _kuwaharaMaterial, 2);
            _kuwaharaMaterial.SetTexture(Tfm, eigenvectors2);

            var passes = settings.kuwaharaSettings.passes;
            
            var kuwaharaPasses = new RenderTexture[passes];

            for (var i = 0; i < passes; ++i)
            {
                kuwaharaPasses[i] = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            }

            Graphics.Blit(source, kuwaharaPasses[0], _kuwaharaMaterial, 3);

            for (var i = 1; i < passes; ++i)
            {
                Graphics.Blit(kuwaharaPasses[i - 1], kuwaharaPasses[i], _kuwaharaMaterial, 3);
            }
            
            var edgeFlowTexture = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(eigenvectors2, edgeFlowTexture, _edgeFlowMaterial, -1);
            
            _compositorMaterial.SetTexture(EdgeFlowTex, edgeFlowTexture);

            Graphics.Blit(kuwaharaPasses[passes - 1], destination, _compositorMaterial, -1);

            // Cleanup
            RenderTexture.ReleaseTemporary(structureTensor);
            RenderTexture.ReleaseTemporary(eigenvectors1);
            RenderTexture.ReleaseTemporary(eigenvectors2);
            for (var i = 0; i < settings.kuwaharaSettings.passes; ++i)
            {
                RenderTexture.ReleaseTemporary(kuwaharaPasses[i]);
            }

            RenderTexture.ReleaseTemporary(edgeFlowTexture);
        }

        private void Setup()
        {
            SetupKuwahara(settings.kuwaharaSettings);
            SetupEdgeFlow(settings.edgeFlowSettings);
            SetupCompositor(settings.compositorSettings);
        }

        private void SetupKuwahara(KuwaharaSettings kuwaharaSettings)
        {
            _kuwaharaMaterial.SetInt(KernelSize, kuwaharaSettings.kernelSize);
            _kuwaharaMaterial.SetFloat(Sharpness, kuwaharaSettings.sharpness);
            _kuwaharaMaterial.SetFloat(Hardness, kuwaharaSettings.hardness);
            _kuwaharaMaterial.SetFloat(Alpha, kuwaharaSettings.alpha);
            _kuwaharaMaterial.SetFloat(ZeroCrossing, kuwaharaSettings.zeroCrossing);
            _kuwaharaMaterial.SetFloat(Zeta,
                kuwaharaSettings.enableZeta
                    ? kuwaharaSettings.zeta
                    : 2.0f / 2.0f / (kuwaharaSettings.kernelSize / 2.0f));
            _kuwaharaMaterial.SetInt(N, 8);
        }

        private void SetupEdgeFlow(EdgeFlowSettings edgeFlowSettings)
        {
            _edgeFlowMaterial.SetTexture(NoiseTex, edgeFlowSettings.noiseTexture);
            _edgeFlowMaterial.SetInt(StreamLineLength, edgeFlowSettings.streamLineLength);
            _edgeFlowMaterial.SetFloat(StreamKernelStrength, edgeFlowSettings.streamKernelStrength);
        }

        private void SetupCompositor(CompositorSettings compositorSettings)
        {
            _compositorMaterial.SetFloat(EdgeContribution, compositorSettings.edgeContribution);
            _compositorMaterial.SetFloat(FlowContribution, compositorSettings.flowContribution);
            _compositorMaterial.SetFloat(DepthContribution, compositorSettings.depthContribution);
            _compositorMaterial.SetFloat(BumpPower, compositorSettings.bumpPower);
            _compositorMaterial.SetFloat(BumpIntensity, compositorSettings.bumpIntensity);
        }

        [Serializable]
        public class Settings
        {
            public KuwaharaSettings kuwaharaSettings;
            public EdgeFlowSettings edgeFlowSettings;
            public CompositorSettings compositorSettings;
        }

        [Serializable]
        public class KuwaharaSettings
        {
            [Header("Properties")] [Range(2, 20)] public int kernelSize = 2;

            [Range(1.0f, 18.0f)] public float sharpness = 8f;
            [Range(1.0f, 100.0f)] public float hardness = 8f;
            [Range(0.01f, 2.0f)] public float alpha = 1f;
            [Range(0.01f, 2.0f)] public float zeroCrossing = 0.6f;

            [Header("Zeta")] [Range(0.01f, 3.0f)] public float zeta = 1f;

            public bool enableZeta;

            [Header("Passes")] [Range(1, 4)] public int passes = 1;
        }

        [Serializable]
        public class EdgeFlowSettings
        {
            public Texture2D noiseTexture;
            [Range(1, 64)] public int streamLineLength = 10;
            [Range(0f, 2f)] public float streamKernelStrength = 0.5f;
        }

        [Serializable]
        public class CompositorSettings
        {
            [Range(0f, 4f)] public float edgeContribution = 1f;
            [Range(0f, 4f)] public float flowContribution = 1f;
            [Range(0f, 4f)] public float depthContribution = 1f;

            [Range(0.25f, 1f)] public float bumpPower = 0.8f;
            [Range(0f, 1f)] public float bumpIntensity = 0.4f;
        }
    }
}