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


//        let captureManager = MTLCaptureManager.shared()
//        let captureScope = captureManager.makeCaptureScope(device: MTLCreateSystemDefaultDevice()!)
//        let captureDescriptor = MTLCaptureDescriptor()
//        captureDescriptor.captureObject = captureScope
//        try captureManager.startCapture(with: captureDescriptor)
//        captureScope.begin()

        let renderer = Renderer(TeapotRenderPass(color: [1, 0, 0, 1], size: CGSize(width: 1600, height: 1200), model: model, view: view, cameraPosition: camera))
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage

//        captureScope.end()


        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
