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

        /* Texture properties */
        sampler2D _MainTex;
        sampler2D _CameraDepthTexture;
        float4 _MainTex_TexelSize;

        /* Shader Properties */
        int _enableOutlining;
        float _colorThreshold;
        float _depthThreshold;
        float _maxDepth;
        float _outlineDimness;

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

            bool ColorSobelFilter(float2 texCoord, float2 texelSize)
            {
                // Gx: Horizontal filter
                // -1,  0,  +1
                // -2,  0,  +2
                // -1,  0,  +1

                // Gy: Vertical filter
                // +1,  +2,  +1
                //  0,   0,   0
                // -1,  -2,  -1

                float2 p1 = texCoord + float2(-1*texelSize.x, texelSize.y);
                float2 p2 = texCoord + float2(0, texelSize.y);
                float2 p3 = texCoord + float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord + float2(-1*texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord + float2(texelSize.x, 0);
                float2 p7 = texCoord + float2(-1*texelSize.x, -1*texelSize.y);
                float2 p8 = texCoord + float2(0, -1*texelSize.y);
                float2 p9 = texCoord + float2(texelSize.x, -1*texelSize.y);

                /* calculate horizontal and vertical gradients */
                float4 g1 = tex2D(_MainTex, p1) + 2*tex2D(_MainTex, p2) + tex2D(_MainTex, p3) - tex2D(_MainTex, p7) - 2*tex2D(_MainTex, p8) - tex2D(_MainTex, p9);
                float4 g2 = tex2D(_MainTex, p3) + 2*tex2D(_MainTex, p6) + tex2D(_MainTex, p9) - tex2D(_MainTex, p1) - 2*tex2D(_MainTex, p4) - tex2D(_MainTex, p7);

                /* calculate gradient magnitude */
                float magnitude = sqrt(dot(g1, g1) + dot(g2, g2));

                if(magnitude > _colorThreshold) {
                    return true;
                }

                return false;
            }

            bool DepthSobelFilter(float2 texCoord, float2 texelSize) {
                float2 p1 = texCoord + float2(-1*texelSize.x, texelSize.y);
                float2 p2 = texCoord + float2(0, texelSize.y);
                float2 p3 = texCoord + float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord + float2(-1*texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord + float2(texelSize.x, 0);
                float2 p7 = texCoord + float2(-1*texelSize.x, -1*texelSize.y);
                float2 p8 = texCoord + float2(0, -1*texelSize.y);
                float2 p9 = texCoord + float2(texelSize.x, -1*texelSize.y);

                float depth_p1 = Linear01Depth(tex2D(_CameraDepthTexture, p1).r) * _ProjectionParams.z;
                float depth_p2 = Linear01Depth(tex2D(_CameraDepthTexture, p2).r) * _ProjectionParams.z;
                float depth_p3 = Linear01Depth(tex2D(_CameraDepthTexture, p3).r) * _ProjectionParams.z;
                float depth_p4 = Linear01Depth(tex2D(_CameraDepthTexture, p4).r) * _ProjectionParams.z;
                float depth_p5 = Linear01Depth(tex2D(_CameraDepthTexture, p5).r) * _ProjectionParams.z;
                float depth_p6 = Linear01Depth(tex2D(_CameraDepthTexture, p6).r) * _ProjectionParams.z;
                float depth_p7 = Linear01Depth(tex2D(_CameraDepthTexture, p7).r) * _ProjectionParams.z;
                float depth_p8 = Linear01Depth(tex2D(_CameraDepthTexture, p8).r) * _ProjectionParams.z;
                float depth_p9 = Linear01Depth(tex2D(_CameraDepthTexture, p9).r) * _ProjectionParams.z;

                float gx = -1*depth_p1 + 1*depth_p3 - 2*depth_p4 + 2*depth_p6 - 1*depth_p7 + 1*depth_p9;
                float gy = 1*depth_p1 + 2*depth_p2 + 1*depth_p3 - 1*depth_p7 - 2*depth_p8 - 1*depth_p9;

                float magnitude = sqrt(dot(gx, gx) + dot(gy, gy));

                if(magnitude > _depthThreshold) {
                    return true; //edge
                }
                return false; //no edge
            }

            float4 getOutlineColor(float2 texCoord, float2 texelSize) {
                float2 depthArray[9];
                depthArray[0] = texCoord + float2(-1*texelSize.x, texelSize.y);
                depthArray[1] = texCoord + float2(0, texelSize.y);
                depthArray[2] = texCoord + float2(texelSize.x, texelSize.y);
                depthArray[3] = texCoord + float2(-1*texelSize.x, 0);
                depthArray[4] = texCoord;
                depthArray[5] = texCoord + float2(texelSize.x, 0);
                depthArray[6] = texCoord + float2(-1*texelSize.x, -1*texelSize.y);
                depthArray[7] = texCoord + float2(0, -1*texelSize.y);
                depthArray[8] = texCoord + float2(texelSize.x, -1*texelSize.y);

                /* calculate average color */
                float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);
                for(int i = 0; i < 9; i++) {
                    color += tex2D(_MainTex, depthArray[i]);
                }
                color /= 9.0f;

                /* darken color */
                color *= _outlineDimness;

                return color;

            }

            fixed4 frag (v2f i) : SV_Target
            {

                if(!_enableOutlining) {
                    return tex2D(_MainTex, i.uv);
                }

                float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);

                if(depth < _maxDepth && (DepthSobelFilter(i.uv, _MainTex_TexelSize) || ColorSobelFilter(i.uv, _MainTex_TexelSize))) {
                    // return float4(0.0, 0.0f, 0.0f, 1.0f);
                    return getOutlineColor(i.uv, _MainTex_TexelSize);
                }
                else {
                    return tex2D(_MainTex, i.uv);
                }
            }
            
            ENDCG
        }
    }
}
