#import <metal_stdlib>

#import "ColorSource.h"
#import "UltraviolenceExampleShaders.h"

using namespace metal;

namespace ColorAdjust {

    [[visible]] float2 mapTextureCoordinateFunction(float2 textureCoordinate, constant void *parameters);

    [[visible]] float4 colorAdjustFunction(float4 inputColor, float2 inputCoordinate, constant void *parameters);

    // TODO: Move
    float2 textureCoordinateForPixel(constant ColorSourceArgumentBuffer &specifier, uint2 position) {
        if (specifier.source == kColorSourceTypeTexture2D) {
            float2 size = float2(specifier.texture2D.get_width(), specifier.texture2D.get_height());
            return (float2(position) + 0.5) / size;
        } else if (specifier.source == kColorSourceTypeDepth2D) {
            float2 size = float2(specifier.depth2D.get_width(), specifier.depth2D.get_height());
            return (float2(position) + 0.5) / size;
        } else {
            return float2(0, 0);
        }
    }

    kernel void colorAdjust(
        constant ColorSourceArgumentBuffer &inputSpecifier [[buffer(0)]],
        constant void *inputParameters [[buffer(1)]],
        texture2d<float, access::read_write> outputTexture [[texture(0)]],
        uint2 thread_position_in_grid [[thread_position_in_grid]]
    ) {
        float2 textureCoordinate = textureCoordinateForPixel(inputSpecifier, thread_position_in_grid);
        textureCoordinate = mapTextureCoordinateFunction(textureCoordinate, inputParameters);
        const float4 inputColor = inputSpecifier.resolve(textureCoordinate);

        float4 newColor = colorAdjustFunction(inputColor, textureCoordinate, inputParameters);
        outputTexture.write(newColor, thread_position_in_grid);
    }

    // MARK: -

    [[stitchable]] float4 multiply(float4 inputColor, float2 inputCoordinate, constant float &inputParameters) {
        return inputColor * inputParameters;
    }

    [[stitchable]] float4 gamma(float4 inputColor, float2 inputCoordinate, constant float &gamma) {
        float invGamma = 1.0 / gamma;
        float3 gammaCorrected = pow(inputColor.rgb, float3(invGamma));
        return float4(gammaCorrected, inputColor.a);
    }

    [[stitchable]] float4 matrix(float4 inputColor, float2 inputCoordinate, constant float4x4 &matrix) {
        return matrix * inputColor;
    }

    [[stitchable]] float4 brightnessContrast(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
        float brightness = params.x;
        float contrast = params.y;
        float3 color = inputColor.rgb + brightness;
        color = (color - 0.5) * contrast + 0.5;
        return float4(saturate(color), inputColor.a);
    }

    [[stitchable]] float4 hsvAdjust(float4 inputColor, float2 inputCoordinate, constant float3 &params) {
        float hueShift = params.x * 3.14159 / 180.0; // Convert degrees to radians
        float saturation = params.y;
        float value = params.z;

        // RGB to HSV
        float3 rgb = inputColor.rgb;
        float cmax = max(rgb.r, max(rgb.g, rgb.b));
        float cmin = min(rgb.r, min(rgb.g, rgb.b));
        float delta = cmax - cmin;

        float h = 0.0;
        if (delta > 0.0) {
            if (cmax == rgb.r) {
                h = fmod((rgb.g - rgb.b) / delta, 6.0);
            } else if (cmax == rgb.g) {
                h = ((rgb.b - rgb.r) / delta) + 2.0;
            } else {
                h = ((rgb.r - rgb.g) / delta) + 4.0;
            }
            h *= 60.0 * 3.14159 / 180.0; // Convert to radians
        }

        float s = (cmax > 0.0) ? (delta / cmax) : 0.0;
        float v = cmax;

        // Adjust HSV
        h += hueShift;
        s = saturate(s * saturation);
        v = saturate(v * value);

        // HSV to RGB
        float c = v * s;
        float x = c * (1.0 - abs(fmod(h * 180.0 / 3.14159 / 60.0, 2.0) - 1.0));
        float m = v - c;

        float3 rgb_out;
        float h_degrees = h * 180.0 / 3.14159;
        if (h_degrees < 60.0) {
            rgb_out = float3(c, x, 0.0);
        } else if (h_degrees < 120.0) {
            rgb_out = float3(x, c, 0.0);
        } else if (h_degrees < 180.0) {
            rgb_out = float3(0.0, c, x);
        } else if (h_degrees < 240.0) {
            rgb_out = float3(0.0, x, c);
        } else if (h_degrees < 300.0) {
            rgb_out = float3(x, 0.0, c);
        } else {
            rgb_out = float3(c, 0.0, x);
        }

        return float4(rgb_out + m, inputColor.a);
    }

    [[stitchable]] float4 colorBalance(float4 inputColor, float2 inputCoordinate, constant float3x2 &params) {
        float3 shadows = float3(params[0][0], params[1][0], params[2][0]);
        float3 highlights = float3(params[0][1], params[1][1], params[2][1]);

        float luminance = dot(inputColor.rgb, float3(0.299, 0.587, 0.114));
        float shadowWeight = 1.0 - luminance;
        float highlightWeight = luminance;

        float3 color = inputColor.rgb;
        color += shadows * shadowWeight;
        color += highlights * highlightWeight;

        return float4(saturate(color), inputColor.a);
    }

    [[stitchable]] float4 levels(float4 inputColor, float2 inputCoordinate, constant float4 &params) {
        float inputBlack = params.x;
        float inputWhite = params.y;
        float gamma = params.z;
        float outputRange = params.w;

        float3 color = inputColor.rgb;
        color = saturate((color - inputBlack) / (inputWhite - inputBlack));
        color = pow(color, float3(1.0 / gamma));
        color = color * outputRange;

        return float4(saturate(color), inputColor.a);
    }

    [[stitchable]] float4 temperatureTint(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
        float temperature = params.x;
        float tint = params.y;

        float3 color = inputColor.rgb;

        // Temperature adjustment (blue-orange)
        color.r += temperature * 0.1;
        color.b -= temperature * 0.1;

        // Tint adjustment (green-magenta)
        color.g += tint * 0.1;
        color.r -= tint * 0.05;
        color.b -= tint * 0.05;

        return float4(saturate(color), inputColor.a);
    }

    [[stitchable]] float4 threshold(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
        float threshold = params.x;
        float smoothness = params.y;

        float luminance = dot(inputColor.rgb, float3(0.299, 0.587, 0.114));

        float edge0 = threshold - smoothness;
        float edge1 = threshold + smoothness;
        float alpha = smoothstep(edge0, edge1, luminance);

        return float4(float3(alpha), inputColor.a);
    }

    [[stitchable]] float4 vignette(float4 inputColor, float2 inputCoordinate, constant float4 &params) {
        float2 center = params.xy;
        float intensity = params.z;
        float radius = params.w;

        float2 coord = inputCoordinate - center;
        float dist = length(coord);

        float vignette = 1.0 - smoothstep(radius * 0.5, radius, dist);
        vignette = mix(1.0, vignette, intensity);

        return float4(inputColor.rgb * vignette, inputColor.a);
    }

    [[stitchable]] float2 mapTextureCoordinateIdentity(float2 textureCoordinate, constant void *parameters) {
        return textureCoordinate;
    }

} // namespace ColorAdjust
