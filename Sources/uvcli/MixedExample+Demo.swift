import AppKit
import Foundation
import ImageIO
import Ultraviolence
import UltraviolenceExamples
import UniformTypeIdentifiers

extension MixedExample: Demo {
    static func main() throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let element = MixedExample(drawableSize: .init(size), colorTexture: offscreenRenderer.colorTexture, depthTexture: offscreenRenderer.depthTexture, modelMatrix: .identity, color: [1, 0, 0, 1], lightDirection: [1, 1, 1])
        let image = try offscreenRenderer.render(element, capture: true).cgImage
        let url = URL(fileURLWithPath: "output.png")
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url.absoluteURL])
    }
}
