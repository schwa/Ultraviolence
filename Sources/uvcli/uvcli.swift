import UniformTypeIdentifiers
import AppKit
import CoreGraphics
import SwiftUI
import Ultraviolence
import Examples
import simd
import BaseSupport
import Metal

@main
struct UVCLI {
    static func main() async throws {

        let camera = simd_float3([0, 2, 6])
        let model = simd_float4x4(yRotation: .degrees(0))
        let view = simd_float4x4(translation: camera).inverse

        let size = CGSize(width: 1600, height: 1200)

        let renderPass = TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: model, view: view, cameraPosition: camera)

//        let renderPass = MixedExample(size: CGSize(width: 1600, height: 1200), geometries: [Teapot()], color: MTLTexture.newTexture(size: CGSize(width: 1600, height: 1200), pixelFormat: .bgra8Unorm_srgb), depth: MTLTexture.newTexture(size: CGSize(width: 1600, height: 1200), pixelFormat: .depth32Float))


        let renderer = Renderer(size: size, content: renderPass)
        let image = try MTLCaptureManager.shared().with(enabled: false) {
            try renderer.render().cgImage
        }
        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

