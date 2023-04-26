using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderScripts
{
    public class EdgeFlow : MonoBehaviour
    {
        public EdgeFlowSettings settings;

        // Private state
        private Material _mRenderMaterial;
        private static readonly int NoiseTex = Shader.PropertyToID("_NoiseTex");
        private static readonly int StreamLineLength = Shader.PropertyToID("_StreamLineLength");
        private static readonly int StreamKernelStrength = Shader.PropertyToID("_StreamKernelStrength");

        // Unity Messages

        private void OnEnable()
        {
            if (settings.edgeFlowShader == null)
            {
                Debug.LogError("Missing a supplied Kuwahara shader");
                return;
            }

            _mRenderMaterial = new Material(settings.edgeFlowShader)
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
            _mRenderMaterial.SetTexture(NoiseTex, settings.noiseTexture);
            _mRenderMaterial.SetInt(StreamLineLength, settings.streamLineLength);
            _mRenderMaterial.SetFloat(StreamKernelStrength, settings.streamKernelStrength);
            
            // var edgeFlowTex = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.RFloat);
            var edgeFlowTex = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

            Graphics.Blit(source, edgeFlowTex, _mRenderMaterial, 0);
            
            Graphics.Blit(edgeFlowTex, destination);
            
            RenderTexture.ReleaseTemporary(edgeFlowTex);
        }
        
        [Serializable]
        public class EdgeFlowSettings
        {
            public Shader edgeFlowShader;
            public Texture2D noiseTexture;

            [Range(1, 64)] public int streamLineLength = 10;
            [Range(0f, 2f)] public float streamKernelStrength = 0.5f;
        }
    }
}