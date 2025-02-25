import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import AppKit

extension MTLTexture {
    func toCGImage() throws -> CGImage {
        assert(self.pixelFormat == .rgba8Unorm)
        var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = try CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue).orThrow(.resourceCreationFailure)
        let data = try context.data.orThrow(.resourceCreationFailure)
        getBytes(data, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return try context.makeImage().orThrow(.resourceCreationFailure)
    }

    func write(to url: URL) throws {
        let image = try toCGImage()
        let destination = try CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil).orThrow(.resourceCreationFailure)
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}

extension URL {
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}
