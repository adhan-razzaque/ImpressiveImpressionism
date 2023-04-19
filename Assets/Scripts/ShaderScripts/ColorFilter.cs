using System;
using UnityEngine;

namespace ShaderScripts
{
    public class ColorFilter : MonoBehaviour
    {
        public Shader colorFilterShader = null;
        private Material _mRenderMaterial;
        
        // Start is called before the first frame update
        private void Start()
        {
            if (colorFilterShader == null)
            {
                Debug.LogError("ColorFilter is missing a shader");
                _mRenderMaterial = null;
                return;
            }
            
            _mRenderMaterial = new Material(colorFilterShader);
        }

        private void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            Graphics.Blit(source, destination, _mRenderMaterial);
        }
    }
}
