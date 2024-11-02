import UniformTypeIdentifiers
import AppKit
import CoreGraphics
import SwiftUI
import Ultraviolence
import Examples

@main
struct UVCLI {
    static func main() async throws {
        let renderer = Renderer(TeapotRenderPass(color: [1, 0, 0, 1], size: CGSize(width: 1600, height: 1200), model: .init(translation: [0, 0, 0]), view: .init(translation: [0, 0, 0]), cameraPosition: [0, 0, 0]))
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage

        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
