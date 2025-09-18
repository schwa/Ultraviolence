import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct ColorAdjustDemoView: View {
    enum AdjustmentFunction: String, CaseIterable {
        case multiply = "Multiply"
        case gamma = "Gamma"
        case matrix = "Matrix"
        case brightnessContrast = "Brightness/Contrast"
        case hsvAdjust = "HSV"
        case colorBalance = "Color Balance"
        case levels = "Levels"
        case temperatureTint = "Temperature/Tint"
        case threshold = "Threshold"
        case vignette = "Vignette"

        var functionName: String {
            switch self {
            case .multiply: return "multiply"
            case .gamma: return "gamma"
            case .matrix: return "matrix"
            case .brightnessContrast: return "brightnessContrast"
            case .hsvAdjust: return "hsvAdjust"
            case .colorBalance: return "colorBalance"
            case .levels: return "levels"
            case .temperatureTint: return "temperatureTint"
            case .threshold: return "threshold"
            case .vignette: return "vignette"
            }
        }
    }

    let sourceTexture: MTLTexture
    let adjustedTexture: MTLTexture
    let sourceLibrary: MTLLibrary

    let adjustSource = """
    #include <metal_stdlib>
    using namespace metal;

    [[ stitchable ]]
    float4 multiply(float4 inputColor, float2 inputCoordinate, constant float &inputParameters) {
        return inputColor * inputParameters;
    }

    [[ stitchable ]]
    float4 gamma(float4 inputColor, float2 inputCoordinate, constant float &gamma) {
        float invGamma = 1.0 / gamma;
        float3 gammaCorrected = pow(inputColor.rgb, float3(invGamma));
        return float4(gammaCorrected, inputColor.a);
    }

    [[ stitchable ]]
    float4 matrix(float4 inputColor, float2 inputCoordinate, constant float4x4 &matrix) {
        return matrix * inputColor;
    }

    [[ stitchable ]]
    float4 brightnessContrast(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
        float brightness = params.x;
        float contrast = params.y;
        float3 color = inputColor.rgb + brightness;
        color = (color - 0.5) * contrast + 0.5;
        return float4(saturate(color), inputColor.a);
    }

    [[ stitchable ]]
    float4 hsvAdjust(float4 inputColor, float2 inputCoordinate, constant float3 &params) {
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

    [[ stitchable ]]
    float4 colorBalance(float4 inputColor, float2 inputCoordinate, constant float3x2 &params) {
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

    [[ stitchable ]]
    float4 levels(float4 inputColor, float2 inputCoordinate, constant float4 &params) {
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

    [[ stitchable ]]
    float4 temperatureTint(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
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

    [[ stitchable ]]
    float4 threshold(float4 inputColor, float2 inputCoordinate, constant float2 &params) {
        float threshold = params.x;
        float smoothness = params.y;

        float luminance = dot(inputColor.rgb, float3(0.299, 0.587, 0.114));

        float edge0 = threshold - smoothness;
        float edge1 = threshold + smoothness;
        float alpha = smoothstep(edge0, edge1, luminance);

        return float4(float3(alpha), inputColor.a);
    }

    [[ stitchable ]]
    float4 vignette(float4 inputColor, float2 inputCoordinate, constant float4 &params) {
        float2 center = params.xy;
        float intensity = params.z;
        float radius = params.w;

        float2 coord = inputCoordinate - center;
        float dist = length(coord);

        float vignette = 1.0 - smoothstep(radius * 0.5, radius, dist);
        vignette = mix(1.0, vignette, intensity);

        return float4(inputColor.rgb * vignette, inputColor.a);
    }

    """

    @State
    var selectedFunction: AdjustmentFunction = .gamma

    @State
    var multiplyValue: Float = 2.0

    @State
    var gammaValue: Float = 2.2

    @State
    var matrixValues = float4x4(
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0]
    )

    @State
    var brightnessContrastValues = SIMD2<Float>(0.0, 1.0) // brightness, contrast

    @State
    var hsvValues = SIMD3<Float>(0.0, 1.0, 1.0) // hue shift (degrees), saturation multiplier, value multiplier

    @State
    var colorBalanceValues = float3x2(
        [0.0, 0.0], // shadows R/C, highlights R/C
        [0.0, 0.0], // shadows G/M, highlights G/M
        [0.0, 0.0]  // shadows B/Y, highlights B/Y
    )

    @State
    var levelsValues = SIMD4<Float>(0.0, 1.0, 1.0, 1.0) // input black, input white, gamma, output range

    @State
    var temperatureTintValues = SIMD2<Float>(0.0, 0.0) // temperature, tint

    @State
    var thresholdValues = SIMD2<Float>(0.5, 0.05) // threshold, smoothness

    @State
    var vignetteValues = SIMD4<Float>(0.5, 0.5, 0.8, 0.8) // center x, center y, intensity, radius

    public init() {
        let device = _MTLCreateSystemDefaultDevice()

        let textureLoader = MTKTextureLoader(device: device)

        sourceTexture = try! textureLoader.newTexture(name: "4.2.03", scaleFactor: 1, bundle: .main, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
            .SRGB: false
        ])

        let adjustedDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        adjustedDescriptor.usage = [.shaderRead, .shaderWrite]
        adjustedTexture = device.makeTexture(descriptor: adjustedDescriptor)!

        // TODO: #278 Use Ultraviolence's normal shader loading capabilities
        // TODO: #279 Use proper Metal function loading - this one requires all functions to be named the same.
        sourceLibrary = try! device.makeLibrary(source: adjustSource, options: nil)
    }

    var currentParameter: Any {
        switch selectedFunction {
        case .multiply:
            return multiplyValue
        case .gamma:
            return gammaValue
        case .matrix:
            return matrixValues
        case .brightnessContrast:
            return brightnessContrastValues
        case .hsvAdjust:
            return hsvValues
        case .colorBalance:
            return colorBalanceValues
        case .levels:
            return levelsValues
        case .temperatureTint:
            return temperatureTintValues
        case .threshold:
            return thresholdValues
        case .vignette:
            return vignetteValues
        }
    }

    public var body: some View {
        RenderView { _, _ in
            let colorAdjustFunction = sourceLibrary.makeFunction(name: selectedFunction.functionName)!

            switch selectedFunction {
            case .multiply:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: multiplyValue, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .gamma:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: gammaValue, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .matrix:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: matrixValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .brightnessContrast:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: brightnessContrastValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .hsvAdjust:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: hsvValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .colorBalance:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: colorBalanceValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .levels:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: levelsValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .temperatureTint:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: temperatureTintValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .threshold:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: thresholdValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            case .vignette:
                try ComputePass(label: "ColorAdjust") {
                    ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: vignetteValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
                }
            }
            try RenderPass {
                try BillboardRenderPipeline(specifier: .texture2D(adjustedTexture))
            }
        }
        .overlay(alignment: .topTrailing) {
            Form {
                VStack(alignment: .leading) {
                    Picker("Function", selection: $selectedFunction) {
                        ForEach(AdjustmentFunction.allCases, id: \.self) { function in
                            Text(function.rawValue).tag(function)
                        }
                    }
                    .pickerStyle(.menu)

                    Divider()

                    switch selectedFunction {
                    case .multiply:
                        HStack {
                            Text("Multiply Factor:")
                            Slider(value: $multiplyValue, in: 0...10)
                                .frame(minWidth: 200)
                            Text("\(multiplyValue, format: .number.precision(.fractionLength(2)))")
                                .frame(width: 50)
                        }

                    case .gamma:
                        HStack {
                            Text("Gamma:")
                            Slider(value: $gammaValue, in: 0.1...5.0)
                                .frame(minWidth: 200)
                            Text("\(gammaValue, format: .number.precision(.fractionLength(2)))")
                                .frame(width: 50)
                        }

                    case .matrix:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Matrix Transform:")
                                    .font(.caption)
                                Spacer()
                                Menu {
                                    Button("Identity") {
                                        matrixValues = float4x4(
                                            [1.0, 0.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Divider()
                                    Button("Sepia") {
                                        matrixValues = float4x4(
                                            [0.393, 0.349, 0.272, 0.0],
                                            [0.769, 0.686, 0.534, 0.0],
                                            [0.189, 0.168, 0.131, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Grayscale") {
                                        matrixValues = float4x4(
                                            [0.299, 0.299, 0.299, 0.0],
                                            [0.587, 0.587, 0.587, 0.0],
                                            [0.114, 0.114, 0.114, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Invert") {
                                        matrixValues = float4x4(
                                            [-1.0, 0.0, 0.0, 1.0],
                                            [0.0, -1.0, 0.0, 1.0],
                                            [0.0, 0.0, -1.0, 1.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Divider()
                                    Button("Vintage") {
                                        matrixValues = float4x4(
                                            [0.5, 0.3, 0.2, 0.0],
                                            [0.4, 0.6, 0.3, 0.0],
                                            [0.3, 0.2, 0.5, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Cold") {
                                        matrixValues = float4x4(
                                            [0.8, 0.0, 0.0, 0.0],
                                            [0.0, 0.9, 0.0, 0.0],
                                            [0.0, 0.0, 1.2, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Warm") {
                                        matrixValues = float4x4(
                                            [1.2, 0.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 0.0, 0.8, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Divider()
                                    Button("High Contrast") {
                                        matrixValues = float4x4(
                                            [1.5, 0.0, 0.0, -0.25],
                                            [0.0, 1.5, 0.0, -0.25],
                                            [0.0, 0.0, 1.5, -0.25],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Low Contrast") {
                                        matrixValues = float4x4(
                                            [0.5, 0.0, 0.0, 0.25],
                                            [0.0, 0.5, 0.0, 0.25],
                                            [0.0, 0.0, 0.5, 0.25],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Polaroid") {
                                        matrixValues = float4x4(
                                            [1.438, -0.062, -0.062, 0.0],
                                            [-0.122, 1.378, -0.122, 0.0],
                                            [-0.016, -0.016, 1.483, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Divider()
                                    Button("Red Channel Only") {
                                        matrixValues = float4x4(
                                            [1.0, 0.0, 0.0, 0.0],
                                            [1.0, 0.0, 0.0, 0.0],
                                            [1.0, 0.0, 0.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Green Channel Only") {
                                        matrixValues = float4x4(
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Blue Channel Only") {
                                        matrixValues = float4x4(
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Divider()
                                    Button("Swap R↔G") {
                                        matrixValues = float4x4(
                                            [0.0, 1.0, 0.0, 0.0],
                                            [1.0, 0.0, 0.0, 0.0],
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Swap R↔B") {
                                        matrixValues = float4x4(
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [1.0, 0.0, 0.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                    Button("Swap G↔B") {
                                        matrixValues = float4x4(
                                            [1.0, 0.0, 0.0, 0.0],
                                            [0.0, 0.0, 1.0, 0.0],
                                            [0.0, 1.0, 0.0, 0.0],
                                            [0.0, 0.0, 0.0, 1.0]
                                        )
                                    }
                                } label: {
                                    Label("Presets", systemImage: "slider.horizontal.3")
                                }
                                .buttonStyle(.bordered)
                            }
                            ForEach(0..<4) { row in
                                HStack(spacing: 4) {
                                    ForEach(0..<4) { col in
                                        TextField("", value: Binding(
                                            get: { matrixValues[col][row] },
                                            set: { matrixValues[col][row] = Float($0) }
                                        ), format: .number.precision(.fractionLength(2)))
                                        .frame(width: 60)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                }
                            }
                        }

                    case .brightnessContrast:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Brightness:")
                                Slider(value: $brightnessContrastValues.x, in: -1...1)
                                    .frame(minWidth: 200)
                                Text("\(brightnessContrastValues.x, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Contrast:")
                                Slider(value: $brightnessContrastValues.y, in: 0...2)
                                    .frame(minWidth: 200)
                                Text("\(brightnessContrastValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .hsvAdjust:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Hue:")
                                Slider(value: $hsvValues.x, in: -180...180)
                                    .frame(minWidth: 200)
                                Text("\(hsvValues.x, format: .number.precision(.fractionLength(0)))°")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Saturation:")
                                Slider(value: $hsvValues.y, in: 0...2)
                                    .frame(minWidth: 200)
                                Text("\(hsvValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Value:")
                                Slider(value: $hsvValues.z, in: 0...2)
                                    .frame(minWidth: 200)
                                Text("\(hsvValues.z, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .colorBalance:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shadows:").font(.caption)
                            HStack {
                                Text("R/C:")
                                Slider(value: $colorBalanceValues[0][0], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[0][0], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("G/M:")
                                Slider(value: $colorBalanceValues[1][0], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[1][0], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("B/Y:")
                                Slider(value: $colorBalanceValues[2][0], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[2][0], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            Text("Highlights:").font(.caption)
                            HStack {
                                Text("R/C:")
                                Slider(value: $colorBalanceValues[0][1], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[0][1], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("G/M:")
                                Slider(value: $colorBalanceValues[1][1], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[1][1], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("B/Y:")
                                Slider(value: $colorBalanceValues[2][1], in: -0.5...0.5)
                                    .frame(minWidth: 150)
                                Text("\(colorBalanceValues[2][1], format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .levels:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Black Point:")
                                Slider(value: $levelsValues.x, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(levelsValues.x, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("White Point:")
                                Slider(value: $levelsValues.y, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(levelsValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Gamma:")
                                Slider(value: $levelsValues.z, in: 0.1...10)
                                    .frame(minWidth: 200)
                                Text("\(levelsValues.z, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Output Range:")
                                Slider(value: $levelsValues.w, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(levelsValues.w, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .temperatureTint:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperature:")
                                Slider(value: $temperatureTintValues.x, in: -1...1)
                                    .frame(minWidth: 200)
                                Text("\(temperatureTintValues.x, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Tint:")
                                Slider(value: $temperatureTintValues.y, in: -1...1)
                                    .frame(minWidth: 200)
                                Text("\(temperatureTintValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .threshold:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Threshold:")
                                Slider(value: $thresholdValues.x, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(thresholdValues.x, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Smoothness:")
                                Slider(value: $thresholdValues.y, in: 0...0.5)
                                    .frame(minWidth: 200)
                                Text("\(thresholdValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }

                    case .vignette:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Center X:")
                                Slider(value: $vignetteValues.x, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(vignetteValues.x, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Center Y:")
                                Slider(value: $vignetteValues.y, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(vignetteValues.y, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Intensity:")
                                Slider(value: $vignetteValues.z, in: 0...1)
                                    .frame(minWidth: 200)
                                Text("\(vignetteValues.z, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                            HStack {
                                Text("Radius:")
                                Slider(value: $vignetteValues.w, in: 0.1...2)
                                    .frame(minWidth: 200)
                                Text("\(vignetteValues.w, format: .number.precision(.fractionLength(2)))")
                                    .frame(width: 50)
                            }
                        }
                    }
                }
                .frame(minWidth: 350)
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }
}
