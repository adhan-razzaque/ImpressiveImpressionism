Shader "Hidden/Kuwahara"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        static const float pi = 3.14159265358979323846f;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f {
            float2 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
        };

        // Properties
        sampler2D _MainTex;
        sampler2D tfm;

        float4 main_tex_texel_size;

        int kernel_size;
        int size;
        int n;

        float sharpness;
        float alpha;
        float zeta;
        float zero_crossing;
        float hardness;

        // Helper functions

        // Same vertex shader across all passes
        v2f vert (appdata i)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(i.vertex);
            o.uv = i.uv;
            return o;
        }

        // Calculate normal distribution given a sigma and position
        float gaussian_distribution(const float sigma, const float position)
        {
            return (1.0f / (sigma * sqrt(2.0f * pi))) * exp(-0.5f * ((position * position) / (sigma * sigma)));
        }
        ENDCG

        // Calculate Eigenvector for point
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i): SV_Target
            {
                float2 d = main_tex_texel_size.xy;

                const float3 Sx = (
                    1.0f * tex2D(_MainTex, i.uv + float2(-d.x, -d.y)).rgb +
                    2.0f * tex2D(_MainTex, i.uv + float2(-d.x, 0.0)).rgb +
                    1.0f * tex2D(_MainTex, i.uv + float2(-d.x, d.y)).rgb +
                    -1.0f * tex2D(_MainTex, i.uv + float2(d.x, -d.y)).rgb +
                    -2.0f * tex2D(_MainTex, i.uv + float2(d.x, 0.0)).rgb +
                    -1.0f * tex2D(_MainTex, i.uv + float2(d.x, d.y)).rgb
                ) / 4.0f;

                const float3 Sy = (
                    1.0f * tex2D(_MainTex, i.uv + float2(-d.x, -d.y)).rgb +
                    2.0f * tex2D(_MainTex, i.uv + float2(0.0, -d.y)).rgb +
                    1.0f * tex2D(_MainTex, i.uv + float2(d.x, -d.y)).rgb +
                    -1.0f * tex2D(_MainTex, i.uv + float2(-d.x, d.y)).rgb +
                    -2.0f * tex2D(_MainTex, i.uv + float2(0.0, d.y)).rgb +
                    -1.0f * tex2D(_MainTex, i.uv + float2(d.x, d.y)).rgb
                ) / 4.0f;


                return float4(dot(Sx, Sx), dot(Sy, Sy), dot(Sx, Sy), 1.0f);
            }
            ENDCG
        }

        // Blur 1
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                const int kernel_radius = 5;

                float4 col = 0;
                float kernel_sum = 0.0f;

                for (int x = -kernel_radius; x <= kernel_radius; ++x)
                {
                    const float4 c = tex2D(_MainTex, i.uv + float2(x, 0) * main_tex_texel_size.xy);
                    const float gauss = gaussian_distribution(2.0f, x);

                    col += c * gauss;
                    kernel_sum += gauss;
                }

                return col / kernel_sum;
            }
            ENDCG
        }
        
        // Blur 2
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target {
                const int kernel_radius = 5;

                float4 col = 0;
                float kernel_sum = 0.0f;

                for (int y = -kernel_radius; y <= kernel_radius; ++y) {
                    const float4 c = tex2D(_MainTex, i.uv + float2(0, y) * main_tex_texel_size.xy);
                    const float gauss = gaussian_distribution(2.0f, y);

                    col += c * gauss;
                    kernel_sum += gauss;
                }

                float3 g = col.rgb / kernel_sum;

                const float lambda1 = 0.5f * (g.y + g.x + sqrt(g.y * g.y - 2.0f * g.x * g.y + g.x * g.x + 4.0f * g.z * g.z));
                const float lambda2 = 0.5f * (g.y + g.x - sqrt(g.y * g.y - 2.0f * g.x * g.y + g.x * g.x + 4.0f * g.z * g.z));

                const float2 v = float2(lambda1 - g.x, -g.z);
                float2 t = length(v) > 0.0 ? normalize(v) : float2(0.0f, 1.0f);
                float phi = -atan2(t.y, t.x);

                float a = (lambda1 + lambda2 > 0.0f) ? (lambda1 - lambda2) / (lambda1 + lambda2) : 0.0f;
                
                return float4(t, phi, a);
            }
            ENDCG
        }

        // Anisotropic Kuwahara 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                const float frag_alpha = alpha;
                float4 t = tex2D(tfm, i.uv);

                const int kernel_radius = kernel_size / uint(2);
                const float a = float(kernel_radius) * clamp((frag_alpha + t.w) / frag_alpha, 0.1f, 2.0f);
                const float b = float(kernel_radius) * clamp(frag_alpha / (frag_alpha + t.w), 0.1f, 2.0f);

                const float cos_phi = cos(t.z);
                const float sin_phi = sin(t.z);

                const float2x2 rotate = {
                    cos_phi, -sin_phi,
                    sin_phi, cos_phi
                };

                const float2x2 scale = {
                    0.5f / a, 0.0f,
                    0.0f, 0.5f / b
                };

                const float2x2 transform = mul(scale, rotate);

                const int max_x = int(sqrt(a * a * cos_phi * cos_phi + b * b * sin_phi * sin_phi));
                const int max_y = int(sqrt(a * a * sin_phi * sin_phi + b * b * cos_phi * cos_phi));

                float frag_zeta = zeta;

                const float frag_zero_crossing = zero_crossing;
                const float sin_zero_crossing = sin(frag_zero_crossing);
                const float eta = (zeta + cos(frag_zero_crossing)) / (sin_zero_crossing * sin_zero_crossing);

                // Constant size to avoid dynamically sized array
                // Make sure n <= 8
                float4 m[8];
                float3 s[8];

                int k;
                
                for (k = 0; k < n; ++k)
                {
                    m[k] = 0.0f;
                    s[k] = 0.0f;
                }

                [loop]
                for (int y = -max_y; y <= max_y; ++y)
                {
                    [loop]
                    for (int x = -max_x; x <= max_x; ++x)
                    {
                        float2 v = mul(transform, float2(x, y));
                        if (dot(v, v) <= 0.25f)
                        {
                            float3 c = tex2D(_MainTex, i.uv + float2(x, y) * main_tex_texel_size.xy).rgb;
                            c = saturate(c);
                            float sum = 0;
                            float w[8];
                            float z, vxx, vyy;

                            /* Calculate Polynomial Weights */
                            vxx = zeta - eta * v.x * v.x;
                            vyy = zeta - eta * v.y * v.y;
                            z = max(0, v.y + vxx);
                            w[0] = z * z;
                            sum += w[0];
                            z = max(0, -v.x + vyy);
                            w[2] = z * z;
                            sum += w[2];
                            z = max(0, -v.y + vxx);
                            w[4] = z * z;
                            sum += w[4];
                            z = max(0, v.x + vyy);
                            w[6] = z * z;
                            sum += w[6];
                            v = sqrt(2.0f) / 2.0f * float2(v.x - v.y, v.x + v.y);
                            vxx = zeta - eta * v.x * v.x;
                            vyy = zeta - eta * v.y * v.y;
                            z = max(0, v.y + vxx);
                            w[1] = z * z;
                            sum += w[1];
                            z = max(0, -v.x + vyy);
                            w[3] = z * z;
                            sum += w[3];
                            z = max(0, -v.y + vxx);
                            w[5] = z * z;
                            sum += w[5];
                            z = max(0, v.x + vyy);
                            w[7] = z * z;
                            sum += w[7];

                            float g = exp(-3.125f * dot(v, v)) / sum;

                            for (k = 0; k < 8; ++k)
                            {
                                float wk = w[k] * g;
                                m[k] += float4(c * wk, wk);
                                s[k] += c * c * wk;
                            }
                        }
                    }
                }

                float4 output = 0;
                for (k = 0; k < n; ++k)
                {
                    m[k].rgb /= m[k].w;
                    s[k] = abs(s[k] / m[k].w - m[k].rgb * m[k].rgb);

                    float sigma2 = s[k].r + s[k].g + s[k].b;
                    float w = 1.0f / (1.0f + pow(hardness * 1000.0f * sigma2, 0.5f * sharpness));

                    output += float4(m[k].rgb * w, w);
                }

                return saturate(output / output.w);
            }
            ENDCG
        }
    }
}