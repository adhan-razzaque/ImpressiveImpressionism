Shader "Hidden/OilPaintingEffectCompositor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CameraDepthTexture ("Depth", 2D) = "white" {}
        _EdgeFlowTex ("Edge Flow", 2D) = "white" {}

        _EdgeContribution ("Edge Contribution", Range(0, 4)) = 1
        _FlowContribution ("Flow Contribution", Range(0, 4)) = 1
        _DepthContribution ("Depth Contribution", Range(0, 4)) = 1

        _BumpPower ("Bump Power", Range(0.25, 1)) = 0.8
        _BumpIntensity("Bump Intensity", Range(0, 1)) = 0.4
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
            #define PIXEL_X (_ScreenParams.z - 1)
            #define PIXEL_Y (_ScreenParams.w - 1)

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            sampler2D _EdgeFlowTex;

            float _EdgeContribution;
            float _FlowContribution;
            float _DepthContribution;

            float _BumpPower;
            float _BumpIntensity;

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

            float SampleDepth(float2 uv)
            {
                return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
            }

            float3 SampleMain(float2 uv)
            {
                return tex2D(_MainTex, uv).rgb;
            }

            float SampleEdgeFlow(float2 uv)
            {
                return tex2D(_EdgeFlowTex, uv).r;
            }

            float3 SobelU(float2 uv)
            {
                return (
                    -1.0f * SampleMain(uv + float2(-PIXEL_X, -PIXEL_Y)) +
                    -2.0f * SampleMain(uv + float2(-PIXEL_X, 0)) +
                    -1.0f * SampleMain(uv + float2(-PIXEL_X, PIXEL_Y)) +

                    1.0f * SampleMain(uv + float2(PIXEL_X, -PIXEL_Y)) +
                    2.0f * SampleMain(uv + float2(PIXEL_X, 0)) +
                    1.0f * SampleMain(uv + float2(PIXEL_X, PIXEL_Y))
                ) / 4.0;
            }

            float3 SobelV(float2 uv)
            {
                return (
                    -1.0f * SampleMain(uv + float2(-PIXEL_X, -PIXEL_Y)) +
                    -2.0f * SampleMain(uv + float2(0, -PIXEL_Y)) +
                    -1.0f * SampleMain(uv + float2(PIXEL_X, -PIXEL_Y)) +

                    1.0f * SampleMain(uv + float2(-PIXEL_X, PIXEL_Y)) +
                    2.0f * SampleMain(uv + float2(0, PIXEL_Y)) +
                    1.0f * SampleMain(uv + float2(PIXEL_X, PIXEL_Y))
                ) / 4.0;
            }

            float GetHeight(float2 uv)
            {
                float3 edgeU = SobelU(uv);
                float3 edgeV = SobelV(uv);
                float edgeFlow = SampleEdgeFlow(uv);
                float depth = SampleDepth(uv);

                return _EdgeContribution * (length(edgeU) + length(edgeV)) +
                    _FlowContribution * edgeFlow +
                    _DepthContribution * depth;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 baseColor = SampleMain(i.uv);

                float bumpAbove = GetHeight(i.uv + float2(0, PIXEL_Y));
                float bump = GetHeight(i.uv);

                float diff = bump - bumpAbove;
                diff = sign(diff) * pow(saturate(abs(diff)), _BumpPower);
                
                return fixed4(baseColor + baseColor * diff * _BumpIntensity, 0);
            }
            ENDCG
        }
    }
}