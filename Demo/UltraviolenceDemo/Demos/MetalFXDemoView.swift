import SwiftUI
import Ultraviolence
import Metal
import MetalKit

struct MetalFXDemoView: View {

    let sourceTexture: MTLTexture
    let upscaledTexture: MTLTexture

    init() {
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        let textureLoader = MTKTextureLoader(device: device)
        let inputTextureURL = Bundle.main.url(forResource: "DJSI3956", withExtension: "JPG").orFatalError()
        sourceTexture = try! textureLoader.newTexture(URL: inputTextureURL, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
            .SRGB: true
        ])

        let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width * 2, height: sourceTexture.height * 2, mipmapped: false)
        upscaledTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        upscaledTextureDescriptor.storageMode = .private
        upscaledTexture = device.makeTexture(descriptor: upscaledTextureDescriptor)!
    }

    var body: some View {
        HStack {
            RenderView {
                try RenderPass {
                    try BillboardRenderPipeline(texture: sourceTexture)
                }
            }
            .aspectRatio(CGFloat(sourceTexture.width) / CGFloat(sourceTexture.height), contentMode: .fit)
            .overlay(alignment: .bottom) {
                let size = Measurement(value: Double(sourceTexture.width * sourceTexture.height), unit: UnitInformationStorage.bytes).formatted(.byteCount(style: .memory))
                Text("\(sourceTexture.width) x \(sourceTexture.height) / \(size)").font(.title3)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
            RenderView {
                MetalFXSpatial(inputTexture: sourceTexture, outputTexture: upscaledTexture)
                try RenderPass {
                    try BillboardRenderPipeline(texture: upscaledTexture)
                }
            }
            .aspectRatio(CGFloat(upscaledTexture.width) / CGFloat(upscaledTexture.height), contentMode: .fit)
            .overlay(alignment: .bottom) {
                let size = Measurement(value: Double(upscaledTexture.width * upscaledTexture.height), unit: UnitInformationStorage.bytes).formatted(.byteCount(style: .memory))
                Text("\(upscaledTexture.width) x \(upscaledTexture.height) / \(size)").font(.title3)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
    }
}

extension MetalFXDemoView: DemoView {
}
