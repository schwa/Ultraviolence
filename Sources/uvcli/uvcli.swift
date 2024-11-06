import AppKit
import CoreGraphics
import Metal
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
internal import UltraviolenceSupport
import UniformTypeIdentifiers

@main
public struct UVCLI {
    // Get capture from environment
    static let capture = ProcessInfo.processInfo.environment["CAPTURE"].isTrue

    public static func main() async throws {
        let camera = simd_float3([0, 2, 6])
        let model = simd_float4x4(yRotation: .degrees(0))

        let size = CGSize(width: 1_600, height: 1_200)

        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).orThrow(.resourceCreationFailure).labeled("Color Texture")
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).orThrow(.resourceCreationFailure).labeled("Depth Texture")

        //        let renderPass = Render {
        //            TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: model, view: view, cameraPosition: camera)
        //        }

        let renderPass = MixedExample(size: size, geometries: [Teapot()], colorTexture: colorTexture, depthTexture: depthTexture, camera: camera, model: model)

        let renderer = OffscreenRenderer(size: size, content: renderPass, colorTexture: colorTexture, depthTexture: depthTexture)
        let image = try MTLCaptureManager.shared().with(enabled: capture) {
            try renderer.render().cgImage
        }
        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = try CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil).orThrow(.resourceCreationFailure)
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
