using System;
using UnityEngine;

namespace ShaderScripts
{
    public class ColorFilter : MonoBehaviour
    {
        public Shader colorFilterShader = null;

        //parameters for color range saturations
        [Header("Color Saturations")]
        [Range(0.0f, 90.0f)] public float RedOrange = 55f;
        [Range(0.0f, 90.0f)] public float YellowGreen = 80f;
        [Range(0.0f, 90.0f)] public float BlueIndigo = 70f;
        [Range(0.0f, 90.0f)] public float VioletFuschia = 40f;

        private Material _mRenderMaterial;

        private static readonly int redOrange = Shader.PropertyToID("red_orange");
        private static readonly int yellowGreen = Shader.PropertyToID("yellow_green");
        private static readonly int blueIndigo = Shader.PropertyToID("blue_indigo");
        private static readonly int violetFuschia = Shader.PropertyToID("violet_fuschia");
        
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
            //if (_mRenderMaterial == null) return;

            _mRenderMaterial.SetFloat(redOrange, RedOrange);
            _mRenderMaterial.SetFloat(yellowGreen, YellowGreen);
            _mRenderMaterial.SetFloat(blueIndigo, BlueIndigo);
            _mRenderMaterial.SetFloat(violetFuschia, VioletFuschia);

            Graphics.Blit(source, destination, _mRenderMaterial);
        }
    }
}
