#if canImport(MetalFX)
import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct MetalFXDemoView: View {
    let sourceTexture: MTLTexture

    @State
    private var scaleFactor = 2.0

    @State
    private var upscaledTexture: MTLTexture?

    let imageName = "4.2.03" // Mandrill https://sipi.usc.edu/database/database.php?volume=misc&image=10#top

    public init() {
        let device = _MTLCreateSystemDefaultDevice()
        let textureLoader = MTKTextureLoader(device: device)
        sourceTexture = try! textureLoader.newTexture(name: "4.2.03", scaleFactor: 1, bundle: .main, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
            .SRGB: false
        ])
    }

    public var body: some View {
        VStack {
            HStack {
                Image(imageName)
                    .overlay(alignment: .topLeading) {
                        badge(name: "swiftui")
                    }

                RenderView {
                    try RenderPass {
                        try BillboardRenderPipeline(texture: sourceTexture)
                    }
                }
                .frame(width: Double(sourceTexture.width), height: Double(sourceTexture.height))
                .overlay(alignment: .topLeading) {
                    badge(name: "metal")
                }
                .overlay(alignment: .bottom) {
                    label(texture: sourceTexture)
                }

                if let upscaledTexture {
                    ScrollView([.horizontal, .vertical]) {
                        RenderView {
                            MetalFXSpatial(inputTexture: sourceTexture, outputTexture: upscaledTexture)
                            try RenderPass {
                                try BillboardRenderPipeline(texture: upscaledTexture)
                            }
                        }
                        .frame(width: Double(upscaledTexture.width), height: Double(upscaledTexture.height))
                        .overlay(alignment: .topLeading) {
                            badge(name: "metalfx")
                        }
                        .overlay(alignment: .bottom) {
                            label(texture: upscaledTexture)
                        }
                    }
                }
            }
            .padding()
        }
        Form {
            LabeledContent("Scale Factor") {
                HStack {
                    Slider(value: $scaleFactor, in: 1...16)
                        .frame(width: 320)

                    Text("\(scaleFactor, format: .number)")
                        .frame(width: 100)
                }
            }
            .padding()
        }
        .onChange(of: scaleFactor, initial: true) {
            let device = _MTLCreateSystemDefaultDevice()
            let upscaledTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: Int(Double(sourceTexture.width) * scaleFactor), height: Int(Double(sourceTexture.height) * scaleFactor), mipmapped: false)
            upscaledTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
            upscaledTextureDescriptor.storageMode = .private
            upscaledTexture = device.makeTexture(descriptor: upscaledTextureDescriptor)!
        }
    }

    func badge(name: String) -> some View {
        Image(name)
            .resizable()
            .frame(width: 48, height: 48)
            .padding(4)
            .opacity(0.66)
    }

    @ViewBuilder
    func label(texture: MTLTexture) -> some View {
        let size = Measurement(value: Double(texture.width * texture.height), unit: UnitInformationStorage.bytes).formatted(.byteCount(style: .memory))
        Text("\(texture.width) x \(texture.height) / \(size)").font(.title3)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
    }
}

#endif
