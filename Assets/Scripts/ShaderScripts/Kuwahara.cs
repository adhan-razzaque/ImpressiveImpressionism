using System;
using UnityEngine;

namespace ShaderScripts
{
    public class Kuwahara : MonoBehaviour
    {
        public Shader kuwahara;

        [Header("Properties")] [Range(2, 20)] public int kernelSize = 2;

        [Range(1.0f, 18.0f)] public float sharpness = 8f;
        [Range(1.0f, 100.0f)] public float hardness = 8f;
        [Range(0.01f, 2.0f)] public float alpha = 1f;
        [Range(0.01f, 2.0f)] public float zeroCrossing = 0.6f;

        [Header("Zeta")] [Range(0.01f, 3.0f)] public float zeta = 1f;

        public bool enableZeta;

        [Header("Passes")] [Range(1, 4)] public int passes = 1;

        // Private state

        private Material _mRenderMaterial;

        // Cached properties
        private static readonly int KernelSize = Shader.PropertyToID("kernel_size");
        private static readonly int Sharpness = Shader.PropertyToID("sharpness");
        private static readonly int Hardness = Shader.PropertyToID("hardness");
        private static readonly int Alpha = Shader.PropertyToID("alpha");
        private static readonly int ZeroCrossing = Shader.PropertyToID("zero_crossing");
        private static readonly int Zeta = Shader.PropertyToID("zeta");
        private static readonly int N = Shader.PropertyToID("n");
        private static readonly int Tfm = Shader.PropertyToID("tfm");

        // Unity Messages

        private void OnEnable()
        {
            if (kuwahara == null)
            {
                Debug.LogError("Missing a supplied Kuwahara shader");
                return;
            }
            
            _mRenderMaterial = new Material(kuwahara)
            {
                // Leave destruction up to this script
                hideFlags = HideFlags.HideAndDontSave
            };
        }

        private void OnDisable()
        {
            _mRenderMaterial = null;
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            if (_mRenderMaterial == null) return;
            
            // Set properties
            _mRenderMaterial.SetInt(KernelSize, kernelSize);
            _mRenderMaterial.SetFloat(Sharpness, sharpness);
            _mRenderMaterial.SetFloat(Hardness, hardness);
            _mRenderMaterial.SetFloat(Alpha, alpha);
            _mRenderMaterial.SetFloat(ZeroCrossing, zeroCrossing);
            _mRenderMaterial.SetFloat(Zeta, enableZeta ? zeta : 2.0f / 2.0f / (kernelSize / 2.0f));
            _mRenderMaterial.SetInt(N, 8);

            var structureTensor = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(source, structureTensor, _mRenderMaterial, 0);
            var eigenvectors1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(structureTensor, eigenvectors1, _mRenderMaterial, 1);
            var eigenvectors2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(eigenvectors1, eigenvectors2, _mRenderMaterial, 2);
            _mRenderMaterial.SetTexture(Tfm, eigenvectors2);

            var kuwaharaPasses = new RenderTexture[passes];

            for (var i = 0; i < passes; ++i)
            {
                kuwaharaPasses[i] = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            }

            Graphics.Blit(source, kuwaharaPasses[0], _mRenderMaterial, 3);

            for (var i = 1; i < passes; ++i)
            {
                Graphics.Blit(kuwaharaPasses[i - 1], kuwaharaPasses[i], _mRenderMaterial, 3);
            }

            //Graphics.Blit(structureTensor, destination);
            Graphics.Blit(kuwaharaPasses[passes - 1], destination);

            RenderTexture.ReleaseTemporary(structureTensor);
            RenderTexture.ReleaseTemporary(eigenvectors1);
            RenderTexture.ReleaseTemporary(eigenvectors2);
            for (var i = 0; i < passes; ++i)
            {
                RenderTexture.ReleaseTemporary(kuwaharaPasses[i]);
            }
        }
    }
}