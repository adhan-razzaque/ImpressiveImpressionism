
Shader "Custom/ColorFilter" {
	
    Properties {
		_MainTex("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)
	}

	SubShader {
		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
            #include "UnityCG.cginc"
            
			
			// Properties
			sampler2D _MainTex;
            float4 _Color;

            float abs(float val){
                if(val >= 0.0)
                    return val;
                return val * -1;
            }

            float max(float v1, float v2){
                if(v1 >= v2)
                    return v1;
                return v2;
            }

            float min(float v1, float v2){
                if(v1 >= v2)
                    return v2;
                return v1;
            }

            float trunc(float v){
                float r = v % 1;
                return v - r;
            }

            /**
            * @brief Function to convert from RGB to HSV color space
            * 		  --> this implementation used code as a reference:
            * 		  https://www.programmingalgorithms.com/algorithm/rgb-to-hsv/
            * 
            * @param rgb RGB space color to convert
            * @return HSV converted color
            */
            float4 rgbConverter(float4 rgb) : COLOR {
                float r = rgb[0] * 255;
                float g = rgb[1] * 255;
                float b = rgb[2] * 255;

                float maxVal = max(r, max(g, b));
                float minVal = min(r, max(g, b));
                float span = maxVal - minVal;

                float hue = 0.0;
                float sat = 0.0;
                float val = maxVal;
                if (val == 0.0) {
                    sat = 0.0;
                } else {
                    sat = span / val;
                }

                if (sat == 0.0) {
                    hue = 0.0;
                } else {
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
            * 		  This implementation used code as a reference:
            * 		  --> //https://www.programmingalgorithms.com/algorithm/hsv-to-rgb/
            * 
            * @param hsv HSV color to convert
            * @return converted RGB color
            */
            float4 hsvConverter(float4 hsv) : COLOR {
                float r = 0.0;
                float g = 0.0;
                float b = 0.0;
                float hue = hsv[0];
                float sat = hsv[1];
                float val = hsv[2];

                if (sat == 0) {
                    r = val;
                    g = val;
                    b = val;
                } else {
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

                    switch (i) {
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
            float4 colorFilter(float4 hsv) : COLOR {
                // determine if the color at the current fragment is in line
	            // with expected saturation at this hue
	            float hue = hsv[0];
	            float sat = hsv[1] * 100;
	            float val = hsv[2] * 100;

                if (hue >= 0.0 && hue <= 50.0) {
                    // this is the red-orange range
                    // expected saturation: 55-65%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        //		=> decrease saturation, subdue value
                        //		-----> if it is light, make value darker
                        //		-----> if it is dark, make value lighter
                        if (val > 50.0) {
                            // light
                            sat -= 5.0;
                            val -= 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 5.0;
                            val += 2.0;
                        } else {
                            // neutral
                            sat -= 5.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        //		=> increase saturation, enhance value
                        //		-----> if it is light, make value lighter
                        //		-----> if it is dark, make value darker
                        if (val > 50.0) {
                            // light
                            sat += 5.0;
                            val += 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 5.0;
                            val -= 2.0;
                        } else {
                            // neutral
                            sat += 5.0;
                        }
                    }
                } else if (hue > 50.0 && hue <= 145.0) {
                    // this is the yellow-green range
                    // expected saturation: 35-45%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 5.0;
                            val -= 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 5.0;
                            val += 2.0;
                        } else {
                            // neutral
                            sat -= 5.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 5.0;
                            val += 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 5.0;
                            val -= 2.0;
                        } else {
                            // neutral
                            sat += 5.0;
                        }
                    }
                } else if (hue > 145.0 && hue <= 250.0) {
                    // this is the blue-indigo range
                    // expected saturation: 70-80%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 5.0;
                            val -= 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 5.0;
                            val += 2.0;
                        } else {
                            // neutral
                            sat -= 5.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 5.0;
                            val += 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 5.0;
                            val -= 2.0;
                        } else {
                            // neutral
                            sat += 5.0;
                        }
                    }
                } else {
                    // this is the violet-fuschia range
                    // expected saturation: 40-50%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 5.0;
                            val -= 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 5.0;
                            val += 2.0;
                        } else {
                            // neutral
                            sat -= 5.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 5.0;
                            val += 2.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 5.0;
                            val -= 2.0;
                        } else {
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
                // return hsv;
            }

			float4 frag(v2f_img input) : COLOR {
                // sample texture for color
				float4 base = tex2D(_MainTex, input.uv);
                //Debug.Log("pixel color: " + base);
                
                // translate base color into HSV space
                float4 hsv = rgbConverter(base);

                // apply color filter
                hsv = colorFilter(hsv);

                // translate filtered color into RGB space
                float4 rgb = hsvConverter(hsv);

                //Debug.Log("result color: " + rgb);
                return rgb;
                // return float4(255, 255, 255, 1);
			}

			ENDCG
		}
	}
}

// Shader "Custom/PostProcess"
// {
// 	Properties
// 	{
// 		_MainTex("Texture", 2D) = "white" {}
// 		_Color("Color", Color) = (1, 1, 1, 1)
// 		_VRadius("Vignette Radius", Range(0.0, 1.0)) = 0.8
// 		_VSoft("Vignette Softness", Range(0.0, 1.0)) = 0.5
// 	}

// 	SubShader
// 	{
// 		Pass
// 		{
// 			CGPROGRAM
// 			#pragma vertex vert_img
// 			#pragma fragment frag
//             #include "UnityCG.cginc"
			
// 			// Properties
// 			sampler2D _MainTex;
// 			float4 _Color;
// 			float4 _GlitchColor;
// 			float _VRadius;
// 			float _VSoft;

// 			float4 frag(v2f_img input) : COLOR
// 			{
//                 // sample texture for color
// 				float4 base = tex2D(_MainTex, input.uv);
// 				// average original color and new color
//                 //base = base * _Color;

// 				// add vignette
// 				float distFromCenter = distance(input.uv.xy, float2(0.5, 0.5));
// 				float vignette = smoothstep(_VRadius, _VRadius - _VSoft, distFromCenter);
// 				base = saturate(base * vignette);
				
// 				return base;
// 			}

// 			ENDCG
// 		}
// 	}
// }
