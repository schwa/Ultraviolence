import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import GeometryLite3D
import simd
import MetalKit

public struct DepthDemoView: View {

    @State
    var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 5])

    @State
    var drawableSize: CGSize = .zero

    @State
    var showDepthMap = true

    @State
    var exponent: Float = 50

    @State
    var colorTexture: MTLTexture?

    @State
    var depthTexture: MTLTexture?

    @State
    var adjustedDepthTexture: MTLTexture?

    let teapot = MTKMesh.teapot()

    let adjustSource = """
    #include <metal_stdlib>
    using namespace metal;

    [[ stitchable ]]
    float4 node(float4 inputColor, constant float *inputParameters) {
        return pow(inputColor, inputParameters[0]);
    }
    """

    let linkedFunctions: MTLLinkedFunctions

    public init() {
        let device = _MTLCreateSystemDefaultDevice()

        let sourceLibrary = try! device.makeLibrary(source: adjustSource, options: nil)
        let inputs = [
            MTLFunctionStitchingInputNode(argumentIndex: 0),
            MTLFunctionStitchingInputNode(argumentIndex: 1),
        ]
        let adjust = MTLFunctionStitchingFunctionNode(name: "node", arguments: inputs, controlDependencies: [])

        // TODO: Use Ultraviolence's normal shader loading capabilities [FILE TICKET]
        // TODO: Use property Metal function loading - this one requires all functions to be named the same. [FILE TICKET]
        // TODO: Terrible example of stitchable functions.
        let graph = MTLFunctionStitchingGraph(functionName: "adjustColor", nodes: [adjust], outputNode: adjust, attributes: [])

        let stitchedLibraryDescriptor = MTLStitchedLibraryDescriptor()
        stitchedLibraryDescriptor.functions = [sourceLibrary.makeFunction(name: "node")!]
        stitchedLibraryDescriptor.functionGraphs = [graph]
        let stitchedLibrary = try! device.makeLibrary(stitchedDescriptor: stitchedLibraryDescriptor)
        let stitchedFunction = stitchedLibrary.makeFunction(name: "adjustColor")!

        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.privateFunctions = [stitchedFunction]

        self.linkedFunctions = linkedFunctions
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

                    try ComputePass(label: "ColorAdjust") {
                        ColorAdjustComputePipeline(inputSpecifier: .depth2D(depthTexture, nil), inputParameters: exponent, outputTexture: adjustedDepthTexture)
                    }
                    .environment(\.linkedFunctions, linkedFunctions)

                    try RenderPass(label: "Depth to Screen Pass") {
                        try BillboardRenderPipeline(specifier:showDepthMap ? .texture2D(adjustedDepthTexture, nil) : .texture2D(colorTexture, nil), flippedY: true)
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
                TextField("Exponent", value: $exponent, format: .number)
                Slider(value: $exponent, in: 1...100)
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


