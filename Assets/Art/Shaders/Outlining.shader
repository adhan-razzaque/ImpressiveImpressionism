/*
 * Shader: Outlining
 * Author: Dario Jimenez
 * Co-author/Porting: Adhan Razzaque
 * Date: 10/28/2024
 * Description: This shader applies a color filter to the rendered image.
 * 
 * Acknowledgements:
 * - RGB to HSV conversion algorithm: https://www.programmingalgorithms.com/algorithm/rgb-to-hsv/
 * - HSV to RGB conversion algorithm: https://www.programmingalgorithms.com/algorithm/hsv-to-rgb/
 * 
 * License: MIT License
 */
Shader "Custom/EdgeDetection"
{
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "Outlining"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // The Blit.hlsl file provides the vertex shader (Vert),
            // the input structure (Attributes), and the output structure (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #pragma vertex Vert
            #pragma fragment frag

            // Properties
            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D_X(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            CBUFFER_START(UnityPerMaterial)
                float4 _BlitTexture_TexelSize; // (1/w, 1/h, w, h) "SourceSize"
                float color_threshold;
                float depth_threshold;
                float max_depth;
                float outline_dimness;
            CBUFFER_END

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


            float4 PrewittFilter(sampler2D tex, float2 texCoord, float2 texelSize)
            {
                // Gx: Horizontal filter
                // -1,  0,  +1
                // -1,  0,  +1
                // -1,  0,  +1

                // Gy: Vertical filter
                // +1,  +1,  +1
                //  0,   0,   0
                // -1,  -1,  -1

                float2 p1 = texCoord - float2(-1 * texelSize.x, texelSize.y);
                float2 p2 = texCoord - float2(0, texelSize.y);
                float2 p3 = texCoord - float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord - float2(-1 * texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord - float2(texelSize.x, 0);
                float2 p7 = texCoord - float2(-1 * texelSize.x, -1 * texelSize.y);
                float2 p8 = texCoord - float2(0, -1 * texelSize.y);
                float2 p9 = texCoord - float2(texelSize.x, -1 * texelSize.y);

                float gx = -1 * tex2D(tex, p1) + 1 * tex2D(tex, p3) - 1 * tex2D(tex, p4) + 1 * tex2D(tex, p6) - 1 *
                    tex2D(tex, p7) + 1 * tex2D(tex, p9);
                float gy = 1 * tex2D(tex, p1) + 1 * tex2D(tex, p2) + 1 * tex2D(tex, p3) - 1 * tex2D(tex, p7) - 1 *
                    tex2D(tex, p8) - 1 * tex2D(tex, p9);

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

                float2 p1 = texCoord + float2(-1 * texelSize.x, texelSize.y);
                float2 p2 = texCoord + float2(0, texelSize.y);
                float2 p3 = texCoord + float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord + float2(-1 * texelSize.x, 0);
                // float2 p5 = texCoord;
                float2 p6 = texCoord + float2(texelSize.x, 0);
                float2 p7 = texCoord + float2(-1 * texelSize.x, -1 * texelSize.y);
                float2 p8 = texCoord + float2(0, -1 * texelSize.y);
                float2 p9 = texCoord + float2(texelSize.x, -1 * texelSize.y);

                // Precalculate textures
                float4 p1_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p1);
                float4 p2_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p2);
                float4 p3_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p3);
                float4 p4_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p4);
                // float4 p5_tex = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p5);
                float4 p6_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p6);
                float4 p7_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p7);
                float4 p8_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p8);
                float4 p9_tex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p9);

                /* calculate horizontal and vertical gradients */
                float4 g1 = p1_tex + 2 * p2_tex + p3_tex - p7_tex - 2 * p8_tex - p9_tex;
                float4 g2 = p3_tex + 2 * p6_tex + p9_tex - p1_tex - 2 * p4_tex - p7_tex;

                /* calculate gradient magnitude */
                float magnitude = sqrt(dot(g1, g1) + dot(g2, g2));

                if (magnitude > color_threshold)
                {
                    return true;
                }

                return false;
            }

            bool DepthSobelFilter(float2 texCoord, float2 texelSize)
            {
                float2 p1 = texCoord + float2(-1 * texelSize.x, texelSize.y);
                float2 p2 = texCoord + float2(0, texelSize.y);
                float2 p3 = texCoord + float2(texelSize.x, texelSize.y);
                float2 p4 = texCoord + float2(-1 * texelSize.x, 0);
                float2 p5 = texCoord;
                float2 p6 = texCoord + float2(texelSize.x, 0);
                float2 p7 = texCoord + float2(-1 * texelSize.x, -1 * texelSize.y);
                float2 p8 = texCoord + float2(0, -1 * texelSize.y);
                float2 p9 = texCoord + float2(texelSize.x, -1 * texelSize.y);

                float depth_p1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p1).r *
                    _ProjectionParams.z;
                float depth_p2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p2).r *
                    _ProjectionParams.z;
                float depth_p3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p3).r *
                    _ProjectionParams.z;
                float depth_p4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p4).r *
                    _ProjectionParams.z;
                // float depth_p5 = SAMPLE_DEPTH_TEXTURE(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, p5).r * _ProjectionParams.z;
                float depth_p6 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p6).r *
                    _ProjectionParams.z;
                float depth_p7 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p7).r *
                    _ProjectionParams.z;
                float depth_p8 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p8).r *
                    _ProjectionParams.z;
                float depth_p9 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, p9).r *
                    _ProjectionParams.z;

                float gx = -1 * depth_p1 + 1 * depth_p3 - 2 * depth_p4 + 2 * depth_p6 - 1 * depth_p7 + 1 * depth_p9;
                float gy = 1 * depth_p1 + 2 * depth_p2 + 1 * depth_p3 - 1 * depth_p7 - 2 * depth_p8 - 1 * depth_p9;

                float magnitude = sqrt(dot(gx, gx) + dot(gy, gy));

                if (magnitude > depth_threshold)
                {
                    return true; //edge
                }
                return false; //no edge
            }

            float4 getOutlineColor(float2 texCoord, float2 texelSize)
            {
                // float2 sampleOffset =
                //     float2 (0, (blurPixels / _BlitTexture_TexelSize.w) *
                //         (i / BLUR_SAMPLES_RANGE));
                float d0 = texCoord + float2(-1 * texelSize.x, texelSize.y);
                float d1 = texCoord + float2(0, texelSize.y);
                float d2 = texCoord + float2(texelSize.x, texelSize.y);
                float d3 = texCoord + float2(-1 * texelSize.x, 0);
                float d4 = texCoord;
                float d5 = texCoord + float2(texelSize.x, 0);
                float d6 = texCoord + float2(-1 * texelSize.x, -1 * texelSize.y);
                float d7 = texCoord + float2(0, -1 * texelSize.y);
                float d8 = texCoord + float2(texelSize.x, -1 * texelSize.y);

                /* calculate average color */
                float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);

                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d0);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d1);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d2);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d3);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d4);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d5);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d6);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d7);
                color += SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, d8);

                color /= 9.0f;

                /* darken color */
                color *= outline_dimness;

                return color;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN)


                float2 texel_size = _BlitTexture_TexelSize; // Need to figure out how to pull from texture
                // float2 texel_size = _ScreenParams;
                float4 base = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.texcoord);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, IN.texcoord).r;

                if (depth > max_depth)
                {
                    return base;
                }

                if (false
                    // DepthSobelFilter(IN.texcoord, texel_size)
                    || ColorSobelFilter(IN.texcoord, texel_size)
                )
                {
                    // return float4(0.0, 0.0f, 0.0f, 1.0f);
                    return getOutlineColor(IN.texcoord, texel_size);
                }

                return base;
            }
            ENDHLSL
        }
    }
}