/*
 * Shader: ColorFilter
 * Author: Katie Clark
 * Co-author/Porting: Adhan Razzaque
 * Date: 10/23/2024
 * Description: This shader applies a color filter to the rendered image.
 * 
 * Acknowledgements:
 * - RGB to HSV conversion algorithm: https://www.programmingalgorithms.com/algorithm/rgb-to-hsv/
 * - HSV to RGB conversion algorithm: https://www.programmingalgorithms.com/algorithm/hsv-to-rgb/
 * 
 * License: MIT License
 */
Shader "Custom/ColorFilter"
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
            Name "ColorFilter"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            // Properties
            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            CBUFFER_START(UnityPerMaterial)
                float red_orange;
                float yellow_green;
                float blue_indigo;
                float violet_fuschia;

                float add_red;
                float add_green;
                float add_blue;
            CBUFFER_END


            // Math helper functions

            /**
             * @brief Function to calculate the absolute value of a given number
             * 
             * @param val the value to calculate the absolute value of
             * @return float the absolute value of the given number
             */
            float abs(float val)
            {
                if (val >= 0.0)
                    return val;
                return val * -1;
            }

            /**
             * @brief Function to calculate the maximum of two given numbers
             *
             * @param v1 the first value to compare
             * @param v2 the second value to compare
             * @return float the maximum of the two given numbers
             */
            float max(float v1, float v2)
            {
                if (v1 >= v2)
                    return v1;
                return v2;
            }

            /**
             * @brief Function to calculate the minimum of two given numbers
             *
             * @param v1 the first value to compare
             * @param v2 the second value to compare
             * @return float the minimum of the two given numbers
             */
            float min(float v1, float v2)
            {
                if (v1 >= v2)
                    return v2;
                return v1;
            }

            /**
             * @brief Function to calculate the truncation of a given number
             *
             * @param v the value to truncate
             * @return float the truncated value
             */
            float trunc(float v)
            {
                float r = v % 1;
                return v - r;
            }

            /**
            * @brief Function to convert from RGB to HSV color space
            *         --> this implementation used code as a reference:
            *         https://www.programmingalgorithms.com/algorithm/rgb-to-hsv/
            * 
            * @param rgb RGB space color to convert
            * @return HSV converted color
            */
            float4 rgbConverter(float4 rgb) : COLOR
            {
                float r = rgb[0] * 255;
                float g = rgb[1] * 255;
                float b = rgb[2] * 255;

                float maxVal = max(r, max(g, b));
                float minVal = min(r, min(g, b));
                float span = maxVal - minVal;

                float hue = 0.0;
                float sat = 0.0;
                float val = maxVal;
                if (val == 0.0)
                {
                    sat = 0.0;
                }
                else
                {
                    sat = span / val;
                }

                if (sat == 0.0)
                {
                    hue = 0.0;
                }
                else
                {
                    if (r == val)
                        hue = (g - b) / span;
                    else if (g == val)
                        hue = 2.0 + (b - r) / span;
                    else if (b == val)
                        hue = 4.0 + (r - g) / span;

                    hue *= 60.0;
                    if (hue < 0.0)
                        hue += 360.0;
                }

                return float4(hue, sat, (val / 255.0), 1.0);
            }

            /**
            * @brief Function to convert from HSV to RGB color space
            *         This implementation used code as a reference:
            *         --> //https://www.programmingalgorithms.com/algorithm/hsv-to-rgb/
            * 
            * @param hsv HSV color to convert
            * @return converted RGB color
            */
            float4 hsvConverter(float4 hsv) : COLOR
            {
                float r = 0.0;
                float g = 0.0;
                float b = 0.0;
                float hue = hsv[0];
                float sat = hsv[1];
                float val = hsv[2];

                if (sat == 0)
                {
                    r = val;
                    g = val;
                    b = val;
                }
                else
                {
                    int i;
                    float f, p, q, t;

                    if (hue == 360.0)
                        hue = 0.0;
                    else
                        hue = hue / 60.0;

                    i = (int)(trunc(hue));
                    f = hue - i;
                    p = val * (1.0 - sat);
                    q = val * (1.0 - (sat * f));
                    t = val * (1.0 - (sat * (1.0 - f)));

                    switch (i)
                    {
                    case 0:
                        r = val;
                        g = t;
                        b = p;
                        break;
                    case 1:
                        r = q;
                        g = val;
                        b = p;
                        break;
                    case 2:
                        r = p;
                        g = val;
                        b = t;
                        break;
                    case 3:
                        r = p;
                        g = q;
                        b = val;
                        break;
                    case 4:
                        r = t;
                        g = p;
                        b = val;
                        break;

                    default:
                        r = val;
                        g = p;
                        b = q;
                        break;
                    }
                }

                return float4(r, g, b, 1.0);
            }

            /**
            * @brief Function to apply the "filter" shader to the current fragment
            * 
            * @param hsv the hsv value of this fragment
            * @param rgb the rgb value of this fragment
            * @return Color the adjusted color to be rendered
            */
            float4 colorFilter(float4 hsv) : COLOR
            {
                // determine if the color at the current fragment is in line
                // with expected saturation at this hue
                float hue = hsv[0];
                float sat = hsv[1] * 100;
                float val = hsv[2] * 100;

                if (hue >= 0.0 && hue <= 50.0)
                {
                    // this is the red-orange range
                    // expected saturation: 55-65%
                    if (sat > (red_orange + 10.0))
                    {
                        // create a more muted version of this color
                        //      => decrease saturation, subdue value
                        //      -----> if it is light, make value darker
                        //      -----> if it is dark, make value lighter
                        if (val > 50.0)
                        {
                            // light
                            sat -= 5.0;
                            val -= 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat -= 5.0;
                            val += 5.0;
                        }
                        else
                        {
                            // neutral
                            sat -= 5.0;
                        }
                    }
                    else if (sat < red_orange)
                    {
                        // create a more intense version of this color
                        //      => increase saturation, enhance value
                        //      -----> if it is light, make value lighter
                        //      -----> if it is dark, make value darker
                        if (val > 50.0)
                        {
                            // light
                            sat += 5.0;
                            val += 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat += 5.0;
                            val -= 5.0;
                        }
                        else
                        {
                            // neutral
                            sat += 5.0;
                        }
                    }
                }
                else if (hue > 50.0 && hue <= 145.0)
                {
                    // this is the yellow-green range
                    // expected saturation: 80-90%
                    if (sat > (yellow_green + 10.0))
                    {
                        // create a more muted version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat -= 5.0;
                            val -= 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat -= 5.0;
                            val += 5.0;
                        }
                        else
                        {
                            // neutral
                            sat -= 5.0;
                        }
                    }
                    else if (sat < yellow_green)
                    {
                        // create a more intense version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat += 5.0;
                            val += 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat += 5.0;
                            val -= 5.0;
                        }
                        else
                        {
                            // neutral
                            sat += 5.0;
                        }
                    }
                }
                else if (hue > 145.0 && hue <= 250.0)
                {
                    // this is the blue-indigo range
                    // expected saturation: 70-80%
                    if (sat > (blue_indigo + 10.0))
                    {
                        // create a more muted version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat -= 5.0;
                            val -= 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat -= 5.0;
                            val += 5.0;
                        }
                        else
                        {
                            // neutral
                            sat -= 5.0;
                        }
                    }
                    else if (sat < blue_indigo)
                    {
                        // create a more intense version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat += 5.0;
                            val += 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat += 5.0;
                            val -= 5.0;
                        }
                        else
                        {
                            // neutral
                            sat += 5.0;
                        }
                    }
                }
                else
                {
                    // this is the violet-fuschia range
                    // expected saturation: 40-50%
                    if (sat > (violet_fuschia + 10.0))
                    {
                        // create a more muted version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat -= 5.0;
                            val -= 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat -= 5.0;
                            val += 5.0;
                        }
                        else
                        {
                            // neutral
                            sat -= 5.0;
                        }
                    }
                    else if (sat < violet_fuschia)
                    {
                        // create a more intense version of this color
                        if (val > 50.0)
                        {
                            // light
                            sat += 5.0;
                            val += 5.0;
                        }
                        else if (val < 50.0)
                        {
                            // dark
                            sat += 5.0;
                            val -= 5.0;
                        }
                        else
                        {
                            // neutral
                            sat += 5.0;
                        }
                    }
                }
                // ensure validity of color
                if (hue > 359.0 || hue < 0.0)
                    hue = 359.0;
                if (sat > 100.0)
                    sat = 100.0;
                else if (sat < 0.0)
                    sat = 0.0;
                if (val > 100.0)
                    val = 100.0;
                else if (val < 0.0)
                    val = 0.0;
                sat = sat / 100.0;
                val = val / 100.0;

                return float4(hue, sat, val, 1.0);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN)

                // sample texture for color
                float4 base = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.texcoord);

                // translate base color into HSV space
                float4 hsv = rgbConverter(base);

                // apply color filter
                hsv = colorFilter(hsv);

                // translate filtered color into RGB space
                float4 rgb = hsvConverter(hsv);

                // add color level parameters
                rgb.r += add_red;
                rgb.g += add_green;
                rgb.b += add_blue;

                rgb.r = clamp(rgb.r, 0.0f, 1.0f);
                rgb.g = clamp(rgb.g, 0.0f, 1.0f);
                rgb.b = clamp(rgb.b, 0.0f, 1.0f);

                return rgb;
            }
            ENDHLSL
        }
    }
}