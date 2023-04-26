Shader "Hidden/LineIntegralConvolution"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _NoiseTex ("Noise Texture", 2D) = "white" {}
        
        [IntRange] _StreamLineLength ("Stream Line Length", Range(1, 64)) = 10
        _KernelStrength ("Stream Kernel Strength", Range(0, 2)) = 0.5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define SCREEN_WIDTH _ScreenParams.x
            #define SCREEN_HEIGHT _ScreenParams.y
            #define SCREEN_SIZE _ScreenParams.xy
            #define PIXEL_X (_ScreenParams.z - 1)
            #define PIXEL_Y (_ScreenParams.w - 1)

            #define MAX_LENGTH 64
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            
            sampler2D _NoiseTex;
            float4 _NoiseTex_TexelSize;

            int _StreamLineLength;
            float _KernelStrength;

            float3 SampleMain(float2 uv)
            {
                return tex2D(_MainTex, uv);
            }

            float3 SampleNoise(float2 uv)
            {
                float x = uv.x * SCREEN_WIDTH / _NoiseTex_TexelSize.z;
                float y = uv.y * SCREEN_HEIGHT / _NoiseTex_TexelSize.w;
                return tex2D(_NoiseTex, float2(x, y));
            }

            float2 GetVectorField(float2 uv)
            {
                float2 g = SampleMain(uv);

                float norm = length(g);

                return norm == 0 ? float2(0, 0) : g / norm;
            }

            float2 QuantizeToPixel(float2 uv)
            {
                return floor(uv * SCREEN_SIZE) / SCREEN_SIZE;
            }

            bool InBounds(float2 uv)
            {
                float2 clamped = saturate(uv);
                return clamped == uv;
            }

            float2 FilterKernel(float2 uv, float kernelStrength)
            {
                float2 v = GetVectorField(uv);
                const float2 k1 = v * kernelStrength;

                v = GetVectorField(uv + 0.5f * k1);
                const float2 k2 = v * kernelStrength;

                v = GetVectorField(uv + 0.5f * k2);
                const float2 k3 = v * kernelStrength;

                v = GetVectorField(uv + k3);
                const float2 k4 = v * kernelStrength;

                return uv + (k1 / 6.0f) + (k2 / 3.0f) + (k3 / 3.0f) + (k4 / 6.0f);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Compute stream line
                float2 forwardStream[MAX_LENGTH];
                float2 backwardStream[MAX_LENGTH];

                float2 forward = i.uv;
                float2 backward = i.uv;

                for (int idx = 0; idx < _StreamLineLength; ++idx)
                {
                    float kernelStrength = _KernelStrength * PIXEL_X;

                    forward = FilterKernel(forward, kernelStrength);
                    forwardStream[idx] = forward;

                    backward = FilterKernel(backward, -kernelStrength);
                    backwardStream[idx] = backward;
                }

                for (int idx = 0; idx < _StreamLineLength; ++idx)
                {
                    forwardStream[idx] = QuantizeToPixel(forwardStream[idx]);
                    backwardStream[idx] = QuantizeToPixel(backwardStream[idx]);
                }

                // Integrate stream line
                float3 integral = float3(0, 0, 0);
                int k = 0;

                for (int idx = 0; idx < _StreamLineLength; ++idx)
                {
                    float2 xi = forwardStream[idx];
                    if (InBounds(xi))
                    {
                        integral += SampleNoise(xi);
                        ++k;
                    }

                    xi = backwardStream[idx];
                    if (InBounds(xi))
                    {
                        integral += SampleNoise(xi);
                        ++k;
                    }
                }

                integral /= k;

                return fixed4(integral, 0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}