Shader "Custom/EdgeDetection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        /* properties */
        int _enableEdgeDetection;
        float _colorThreshold;
        float _depthThreshold;

        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_TexelSize;
            float4 __ProjectionParams;


            float4 RobertsCrossFilter(sampler2D tex, float2 texCoord, float2 texelSize)
            {
                // Filter1
                // 1,  0,
                // 0, -1

                // Filter2
                //  0, 1,
                // -1, 0

                float2 uv0 = texCoord;
                float2 uv1 = texCoord + texelSize;
                float2 uv2 = texCoord + float2(texelSize.x, 0);
                float2 uv3 = texCoord + float2(0, texelSize.y);

                float4 g1 = tex2D(tex, uv0) - tex2D(tex, uv1);
                float4 g2 = tex2D(tex, uv2) - tex2D(tex, uv3);

                return sqrt(dot(g1, g1) + dot(g2, g2));
            }

            float4 SobelFilter(sampler2D tex, float2 texCoord, float2 texelSize)
            {
                // Gx: Horizontal filter
                // -1,  0,  +1
                // -2,  0,  +2
                // -1,  0,  +1

                // Gy: Vertical filter
                // +1,  +2,  +1
                //  0,   0,   0
                // -1,  -2,  -1

                float2 p1 = texCoord - float2(-1*texelSize.x, texelSize.y);
                float2 p2 = texCoord - float2(0, texelSize.y);
                float2 p3 = texCoord - float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord - float2(-1*texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord - float2(texelSize.x, 0);
                float2 p7 = texCoord - float2(-1*texelSize.x, -1*texelSize.y);
                float2 p8 = texCoord - float2(0, -1*texelSize.y);
                float2 p9 = texCoord - float2(texelSize.x, -1*texelSize.y);

                // float4 gx = -1*p1 + 1*p3 - 2*p4 + 2*p6 - 1*p7 + 1*p9;

                // float4 gy = 1*p1 + 2*p2 + 1*p3 - 1*p7 - 2*p8 - 1*p9;
                float4 gx = float4(0,0,0,0);
                float4 gy = float4(0,0,0,0);

                gx = -1*tex2D(tex, p1) + 1*tex2D(tex, p3) - 2*tex2D(tex, p4) + 2*tex2D(tex, p6) - 1*tex2D(tex, p7) + 1*tex2D(tex, p9);
                gy = 1*tex2D(tex, p1) + 2*tex2D(tex, p2) + 1*tex2D(tex, p3) - 1*tex2D(tex, p7) - 2*tex2D(tex, p8) - 1*tex2D(tex, p9);

                // float4 g1 = (p1 + 2*p2 + p3) - (p7 + 2*p8 + p9);
                // float4 g2 = (p3 + 2*p6 + p9) - (p1 + 2*p4 + p7);
                // float4 g1 = tex2D(tex, p1) + 2*tex2D(tex, p2) + tex2D(tex, p3) - tex2D(tex, p7) - 2*tex2D(tex, p8) - tex2D(tex, p9);
                // float4 g2 = tex2D(tex, p3) + 2*tex2D(tex, p6) + tex2D(tex, p9) - tex2D(tex, p1) - 2*tex2D(tex, p4) - tex2D(tex, p7);
                // return sqrt(dot(g1, g1)) + sqrt(dot(g2, g2));
                return sqrt(dot(gx, gx) + dot(gy, gy));
            }

            float4 PrewittFilter(sampler2D tex, float2 texCoord, float2 texelSize) {
                // Gx: Horizontal filter
                // -1,  0,  +1
                // -1,  0,  +1
                // -1,  0,  +1

                // Gy: Vertical filter
                // +1,  +1,  +1
                //  0,   0,   0
                // -1,  -1,  -1

                float2 p1 = texCoord - float2(-1*texelSize.x, texelSize.y);
                float2 p2 = texCoord - float2(0, texelSize.y);
                float2 p3 = texCoord - float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord - float2(-1*texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord - float2(texelSize.x, 0);
                float2 p7 = texCoord - float2(-1*texelSize.x, -1*texelSize.y);
                float2 p8 = texCoord - float2(0, -1*texelSize.y);
                float2 p9 = texCoord - float2(texelSize.x, -1*texelSize.y);

                float gx = -1*tex2D(tex, p1) + 1*tex2D(tex, p3) - 1*tex2D(tex, p4) + 1*tex2D(tex, p6) - 1*tex2D(tex, p7) + 1*tex2D(tex, p9);
                float gy = 1*tex2D(tex, p1) + 1*tex2D(tex, p2) + 1*tex2D(tex, p3) - 1*tex2D(tex, p7) - 1*tex2D(tex, p8) - 1*tex2D(tex, p9);

                return sqrt(dot(gx, gx) + dot(gy, gy));
            }

            fixed4 frag (v2f i) : SV_Target
            {

                if(!_enableEdgeDetection) {
                    return tex2D(_MainTex, i.uv);
                }

                float color_gradient = SobelFilter(_MainTex, i.uv, _MainTex_TexelSize.xy);
                float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);

                if(color_gradient > _colorThreshold && depth < _depthThreshold) {
                    return float4(0, 0, 0, 0);
                }
                else {
                    return tex2D(_MainTex, i.uv);
                }
                // return Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r) * _ProjectionParams.z;
            }
            
            ENDCG
        }
    }
}
