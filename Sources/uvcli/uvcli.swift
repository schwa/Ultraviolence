import AppKit
internal import UltraviolenceSupport
import CoreGraphics
import Examples
import Metal
import simd
import SwiftUI
import Ultraviolence
import UniformTypeIdentifiers

@main
public struct UVCLI {

    // Get capture from environment
    static let capture = ProcessInfo.processInfo.environment["CAPTURE"].isTrue

    public static func main() async throws {
        let camera = simd_float3([0, 2, 6])
        let model = simd_float4x4(yRotation: .degrees(0))

        let size = CGSize(width: 1_600, height: 1_200)

        let device = MTLCreateSystemDefaultDevice()!
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget, .shaderWrite]
        let colorTexture = device.makeTexture(descriptor: colorTextureDescriptor)!
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!

//        let renderPass = Render {
//            TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: model, view: view, cameraPosition: camera)
//        }

        let renderPass = MixedExample(size: size, geometries: [Teapot()], color: colorTexture, depth: depthTexture, camera: camera, model: model)



        let renderer = OffscreenRenderer(size: size, content: renderPass)
        let image = try MTLCaptureManager.shared().with(enabled: capture) {
            try renderer.render().cgImage
        }
        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

extension Optional where Wrapped == String {
    var isTrue: Bool {
        guard let value = self?.lowercased() else {
            return false
        }
        return ["1", "true", "yes"].contains(value)
    }
}
