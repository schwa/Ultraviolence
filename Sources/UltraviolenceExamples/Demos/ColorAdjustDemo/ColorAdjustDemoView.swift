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
    let shaderLibrary: Ultraviolence.ShaderLibrary

    @State
    private var selectedFunction: AdjustmentFunction = .gamma

    @State
    private var multiplyValue: Float = 2.0

    @State
    private var gammaValue: Float = 2.2

    @State
    private var matrixValues = float4x4(
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0]
    )

    @State
    private var brightnessContrastValues = SIMD2<Float>(0.0, 1.0) // brightness, contrast

    @State
    private var hsvValues = SIMD3<Float>(0.0, 1.0, 1.0) // hue shift (degrees), saturation multiplier, value multiplier

    @State
    private var colorBalanceValues = float3x2(
        [0.0, 0.0], // shadows R/C, highlights R/C
        [0.0, 0.0], // shadows G/M, highlights G/M
        [0.0, 0.0]  // shadows B/Y, highlights B/Y
    )

    @State
    private var levelsValues = SIMD4<Float>(0.0, 1.0, 1.0, 1.0) // input black, input white, gamma, output range

    @State
    private var temperatureTintValues = SIMD2<Float>(0.0, 0.0) // temperature, tint

    @State
    private var thresholdValues = SIMD2<Float>(0.5, 0.05) // threshold, smoothness

    @State
    private var vignetteValues = SIMD4<Float>(0.5, 0.5, 0.8, 0.8) // center x, center y, intensity, radius

    public init() {
        let device = _MTLCreateSystemDefaultDevice()

        let textureLoader = MTKTextureLoader(device: device)

        let url = Bundle.module.url(forResource: "DSC_2595", withExtension: "JPG")!

        sourceTexture = try! textureLoader.newTexture(URL: url, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .SRGB: false
        ])

        let adjustedDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        adjustedDescriptor.usage = [.shaderRead, .shaderWrite]
        adjustedTexture = device.makeTexture(descriptor: adjustedDescriptor)!
        shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
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
            try ComputePass(label: "ColorAdjust") {
                colorAdjustComputePipeline
            }
            try RenderPass {
                try TextureBillboardPipeline(specifier: .texture2D(adjustedTexture))
            }
        }
        .aspectRatio(Double(sourceTexture.width) / Double(sourceTexture.height), contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            config()
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
        }
    }

    @ElementBuilder
    var colorAdjustComputePipeline: some Element {
        let colorAdjustFunction = try! shaderLibrary.function(named: selectedFunction.functionName, type: VisibleFunction.self)

        switch selectedFunction {
        case .multiply:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: multiplyValue, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .gamma:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: gammaValue, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .matrix:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: matrixValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .brightnessContrast:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: brightnessContrastValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .hsvAdjust:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: hsvValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .colorBalance:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: colorBalanceValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .levels:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: levelsValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .temperatureTint:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: temperatureTintValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .threshold:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: thresholdValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        case .vignette:
            try! ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: vignetteValues, outputTexture: adjustedTexture, colorAdjustFunction: colorAdjustFunction)
        }
    }

    @ViewBuilder
    func config() -> some View {
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
    }
}
