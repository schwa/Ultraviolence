import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import DemoKit

/// A demo that shows transform images using LUTs.
/// I got a bit carried away here and it supports LUTs stored as 512x512 PNGs and .cube 3D LUTs: https://resolve.cafe/developers/luts/
public struct LUTDemoView: View {
    let builtInLUTNames = [
        "Blue Bias.png",
        "65 Point Cube_1.0be85635ffbf1d6253042a9343dcc840542bf5d7ceafcf1e6f4ce96b3f0c66c4.cube",
        "Custom_LUT.cube",
        "Hollywood_-_Cinecom.cube",
        "Linear.png",
        "My_Canon_CLog3_Lut_7.A002C019_2207021U_CANON.cube",
        "Sepia Tone.png",
        "Transfer.png",
        "neutral-lut.png",
        "tweaked.png"
    ]

    @State
    private var blend: Float = 0.0

    @State
    private var sourceTexture: MTLTexture

    @State
    private var lutTexture: MTLTexture

    @State
    private var outputTexture: MTLTexture

    @State
    private var lutURL: URL

    public init() {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let textureLoader = MTKTextureLoader(device: device)
            let inputTextureURL = Bundle.main.url(forResource: "DJSI3956", withExtension: "JPG").orFatalError()
            let sourceTexture = try textureLoader.newTexture(URL: inputTextureURL, options: [
                .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
                .origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
                .SRGB: true
            ])
            let resourceURL = Bundle.main.resourceURL.orFatalError()
            let lutTextureURL = resourceURL.appendingPathComponent("Blue Bias.png").assertFileExists()
            self._lutURL = .init(initialValue: lutTextureURL)
            let lutTexture = try Self.make3DLUTTexture(from: lutTextureURL)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            let outputTexture = try device._makeTexture(descriptor: descriptor)
            self.sourceTexture = sourceTexture
            self.lutTexture = lutTexture
            self.outputTexture = outputTexture
        }
        catch {
            fatalError("\(error)")
        }
    }

    public var body: some View {
        RenderView {
            try Group {
                try ComputePass(label: "LUTDemo") {
                    try LUTComputePipeline(inputTexture: sourceTexture, lutTexture: lutTexture, blend: blend, outputTexture: outputTexture)
                }
                try RenderPass(label: "Billboard") {
                    try BillboardRenderPipeline(texture: outputTexture)
                }
            }
        }
        .metalColorPixelFormat(.rgba16Float) //
        .aspectRatio(Double(sourceTexture.width) / Double(sourceTexture.height), contentMode: .fit)
        .overlay(alignment: .bottom) {
            VStack {
                Picker("LUT", selection: $lutURL) {
                    let resourceURL = Bundle.main.resourceURL.orFatalError()
                    ForEach(builtInLUTNames, id: \.self) { name in
                        let url = resourceURL.appendingPathComponent(name).assertFileExists()
                        Text(name).tag(url)
                    }
                }
                Slider(value: $blend, in: 0...1)
            }
            .frame(maxWidth: 320)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding()
        }
        .onChange(of: lutURL) {
            do {
                let lutTexture = try Self.make3DLUTTexture(from: lutURL)
                self.lutTexture = lutTexture
            } catch {
                fatalError("\(error)")
            }
        }
    }

    static func make3DLUTTexture(from url: URL) throws -> MTLTexture {
        switch url.pathExtension {
        case "cube":
            let cube = try CubeReader(url: url)
            return try cube.toTexture()

        case "png":
            let device = _MTLCreateSystemDefaultDevice()
            let textureLoader = MTKTextureLoader(device: device)
            let lutTexture2D = try textureLoader.newTexture(URL: url, options: [
                .origin: MTKTextureLoader.Origin.topLeft.rawValue,
                .SRGB: true
            ])
            return try create3DLUT(device: device, from: lutTexture2D)!

        default:
            throw UltraviolenceError.undefined
        }
    }
}

extension LUTDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "LUT Color Grading",
            description: "Color grading and correction using Look-Up Tables (LUTs) for cinematic effects",
            keywords: ["lut", "post-processing"]
        )
    }
}

extension URL {
    func assertFileExists() -> URL {
        guard FileManager.default.fileExists(atPath: path) else {
            fatalError("File does not exist: \(path)")
        }
        return self
    }
}
