import SwiftUI
import Ultraviolence
import UltraviolenceUI
import UltraviolenceSupport
import Metal
import MetalKit

public struct ColorAdjustDemoView: View {

    let sourceTexture: MTLTexture
    let adjustedTexture: MTLTexture

    let adjustSource = """
    #include <metal_stdlib>
    using namespace metal;

    [[ stitchable ]]
    float4 adjustColor(float4 inputColor, constant float &inputParameters) {
        return inputColor * inputParameters;
    }
    """

    let linkedFunctions: MTLLinkedFunctions

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

        // TODO: Use Ultraviolence's normal shader loading capabilities [FILE TICKET]
        // TODO: Use property Metal function loading - this one requires all functions to be named the same. [FILE TICKET]
        let sourceLibrary = try! device.makeLibrary(source: adjustSource, options: nil)
        let adjustColorFunction = sourceLibrary.makeFunction(name: "adjustColor")!
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.privateFunctions = [adjustColorFunction]

        self.linkedFunctions = linkedFunctions
    }

    public var body: some View {
        RenderView { _, _ in
            try ComputePass(label: "ColorAdjust") {
                ColorAdjustComputePipeline(inputSpecifier: .texture2D(sourceTexture, nil), inputParameters: Float(0.5), outputTexture: adjustedTexture)
            }
            .environment(\.linkedFunctions, linkedFunctions)

            try RenderPass {
                try BillboardRenderPipeline(specifier: .texture2D(adjustedTexture))
            }
        }
    }
}
