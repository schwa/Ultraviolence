import GeometryLite3D
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct DepthDemoView: View {
    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 5])

    @State
    private var drawableSize: CGSize = .zero

    @State
    private var showDepthMap = true

    @State
    private var exponent: Float = 0.2

    @State
    private var colorTexture: MTLTexture?

    @State
    private var depthTexture: MTLTexture?

    @State
    private var adjustedDepthTexture: MTLTexture?

    let teapot = MTKMesh.teapot()

    let adjustSource = """
    #include <metal_stdlib>
    using namespace metal;

    [[ stitchable ]]
    float4 colorAdjustPow(float4 inputColor, float2 inputCoordinate, constant float &inputParameters) {
        // Invert depth so near objects are white and far objects are black
        // This makes the depth visualization more intuitive
        float depth = 1.0 - inputColor.r;

        // Apply power to increase contrast
        depth = pow(depth, inputParameters);

        return float4(depth, depth, depth, 1.0);
    }
    """
    let colorAdjustFunction: MTLFunction

    public init() {
        let device = _MTLCreateSystemDefaultDevice()

//        let library = ShaderLibrary(source: adjustSource)
//
//        let sourceLibrary = try! device.makeLibrary(source: adjustSource, options: nil)
//        colorAdjustFunction = sourceLibrary.makeFunction(name: "colorAdjustPow")!
        fatalError()
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
            RenderView { _, _ in
                if let colorTexture, let depthTexture, let adjustedDepthTexture {
                    try RenderPass(label: "Teapot to Textures Pass") {
                        try teapotPipeline
                    }
                    .depthAttachment(depthTexture)
                    .renderPassDescriptorModifier { renderPassDescriptor in
                        renderPassDescriptor.colorAttachments[0].texture = colorTexture
                        renderPassDescriptor.colorAttachments[0].loadAction = .clear
                        renderPassDescriptor.colorAttachments[0].storeAction = .store

                        renderPassDescriptor.depthAttachment.texture = depthTexture
                        renderPassDescriptor.depthAttachment.loadAction = .clear
                        renderPassDescriptor.depthAttachment.storeAction = .store
                    }

//                    try ComputePass(label: "ColorAdjust") {
//                        ColorAdjustComputePipeline(inputSpecifier: .depth2D(depthTexture, nil), inputParameters: exponent, outputTexture: adjustedDepthTexture, colorAdjustFunction: colorAdjustFunction)
//                    }

                    try RenderPass(label: "Depth to Screen Pass") {
                        try TextureBillboardPipeline(specifier: showDepthMap ? .texture2D(adjustedDepthTexture, nil) : .texture2D(colorTexture, nil))
                    }
                }
            }
            .onDrawableSizeChange {
                drawableSize = $0

                let device = _MTLCreateSystemDefaultDevice()
                let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int($0.width), height: Int($0.height), mipmapped: false)
                colorDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
                colorTexture = device.makeTexture(descriptor: colorDescriptor)
                colorTexture?.label = "Color Texture"

                let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int($0.width), height: Int($0.height), mipmapped: false)
                depthDescriptor.usage = [.renderTarget, .shaderRead]
                depthTexture = device.makeTexture(descriptor: depthDescriptor)
                depthTexture?.label = "Depth Texture"

                let adjustedDepthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int($0.width), height: Int($0.height), mipmapped: false)
                adjustedDepthDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
                adjustedDepthTexture = device.makeTexture(descriptor: adjustedDepthDescriptor)
                adjustedDepthTexture?.label = "Adjusted Depth Texture"
            }
        }
        .overlay(alignment: .topLeading) {
            Form {
                Toggle("Show Depth Map", isOn: $showDepthMap)
                HStack {
                    Text("Contrast:")
                    Slider(value: $exponent, in: 0.1...10)
                    Text("\(exponent, format: .number.precision(.fractionLength(2)))")
                        .frame(width: 50)
                }
            }
            .frame(maxWidth: 200)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }

    var teapotPipeline: some Element {
        get throws {
            try FlatShader(textureSpecifier: .color([1, 1, 1])) {
                Draw(mtkMesh: teapot)
                    .transforms(Transforms(cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize)))
            }
            .vertexDescriptor(teapot.vertexDescriptor)
            .depthCompare(function: .less, enabled: true)
        }
    }
}
