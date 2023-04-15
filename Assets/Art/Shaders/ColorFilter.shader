
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

            /**
            * @brief Function to convert from RGB to HSV color space
            * 		  --> this implementation used code as a reference:
            * 		  https://www.geeksforgeeks.org/program-change-rgb-color-model-hsv-color-model/
            * 
            * @param rgb RGB space color to convert
            * @return HSV converted color
            */
            float4 rgbConverter(float4 rgb) : COLOR {
                // change from RGB to percentage
                float r = rgb[0] / 255;
                float g = rgb[1] / 255;
                float b = rgb[2] / 255;

                float maxVal = max(r, max(g, b)); // maximum of r, g, b
	            float minVal = min(r, min(g, b)); // minimum of r, g, b
                float span = maxVal - minVal; // span of maxVal and minVal.
                float h = -1, s = -1;

                // if the max and min values are equivalent, 
                // then all values are equal => we are in the grayscale => hue is 0
                if (maxVal == minVal)
                    h = 0;
                else if (maxVal == r)
                    // if red is predominate, use green - blue
                    h = (60 * ((g - b) / span) + 360) % 360;
                else if (maxVal == g)
                    // if green is predominate, use blue - red
                    h = (60 * ((b - r) / span) + 360) % 360;
                else if (maxVal == b)
                    // if blue is predominate, use red - green
                    h = (60 * ((r - g) / span) + 360) % 360;

                // if maxVal equal zero => set saturation to 0 (& avoid div by 0)
                if (maxVal == 0)
                    s = 0;
                else
                    s = (span / maxVal) * 100;

                // compute v
                float v = maxVal * 100;
                return float4(h, s, v, 1.0);
            }

            /**
            * @brief Function to convert from HSV to RGB color space
            * 		  This implementation used code as a reference:
            * 		  --> https://www.codespeedy.com/hsv-to-rgb-in-cpp/
            * 
            * @param hsv HSV color to convert
            * @return converted RGB color
            */
            float4 hsvConverter(float4 hsv) : COLOR {
                // convert s, v to percentages
                float h = hsv[0];
                float s = hsv[1] / 100;
                float v = hsv[2] / 100;

                float c = s * v;
                float x = c * (1 - abs(((h / 60.0) % 2) - 1));
                float m = v - c;
                float r = 0.0;
                float g = 0.0;
                float b = 0.0;

                if (h >= 0.0 && h < 60.0) {
                    r = c;
                    g = x;
                    b = 0;
                } else if (h >= 60.0 && h < 180.0) {
                    r = x;
                    g = c;
                    b = 0;
                } else if (h >= 120.0 && h < 180.0) {
                    r = 0;
                    g = c;
                    b = x;
                } else if (h >= 180.0 && h < 240.0) {
                    r = 0;
                    g = x;
                    b = c;
                } else if (h >= 240.0 && h < 300.0) {
                    r = x;
                    g = 0;
                    b = c;
                } else {
                    r = c;
                    g = 0;
                    b = x;
                }

                r = (r + m) * 255;
	            g = (g + m) * 255;
	            b = (b + m) * 255;
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
	            float sat = hsv[1];
	            float val = hsv[2];

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
                            sat -= 15.0;
                            val -= 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 15.0;
                            val += 10.0;
                        } else {
                            // neutral
                            sat -= 15.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        //		=> increase saturation, enhance value
                        //		-----> if it is light, make value lighter
                        //		-----> if it is dark, make value darker
                        if (val > 50.0) {
                            // light
                            sat += 15.0;
                            val += 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 15.0;
                            val -= 10.0;
                        } else {
                            // neutral
                            sat += 15.0;
                        }
                    }
                } else if (hue > 50.0 && hue <= 145.0) {
                    // this is the yellow-green range
                    // expected saturation: 35-45%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 15.0;
                            val -= 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 15.0;
                            val += 10.0;
                        } else {
                            // neutral
                            sat -= 15.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 15.0;
                            val += 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 15.0;
                            val -= 10.0;
                        } else {
                            // neutral
                            sat += 15.0;
                        }
                    }
                } else if (hue > 145.0 && hue <= 250.0) {
                    // this is the blue-indigo range
                    // expected saturation: 70-80%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 15.0;
                            val -= 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 15.0;
                            val += 10.0;
                        } else {
                            // neutral
                            sat -= 15.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 15.0;
                            val += 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 15.0;
                            val -= 10.0;
                        } else {
                            // neutral
                            sat += 15.0;
                        }
                    }
                } else {
                    // this is the violet-fuschia range
                    // expected saturation: 40-50%
                    if (sat > 65.0) {
                        // create a more muted version of this color
                        if (val > 50.0) {
                            // light
                            sat -= 15.0;
                            val -= 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat -= 15.0;
                            val += 10.0;
                        } else {
                            // neutral
                            sat -= 15.0;
                        }
                    } else if (sat < 55.0) {
                        // create a more intense version of this color
                        if (val > 50.0) {
                            // light
                            sat += 15.0;
                            val += 10.0;
                        } else if (val < 50.0) {
                            // dark
                            sat += 15.0;
                            val -= 10.0;
                        } else {
                            // neutral
                            sat += 15.0;
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

                return float4(hue, sat, val, 1.0);
            }

			float4 frag(v2f_img input) : COLOR {
                // sample texture for color
				float4 base = tex2D(_MainTex, input.uv);
                // translate base color into HSV space
                float4 hsv = rgbConverter(base);
                // apply color filter
                hsv = colorFilter(hsv);
                // translate filtered color into RGB space
                float4 rgb = hsvConverter(hsv);
                return rgb;
			}

			ENDCG
		}
	}
}
