import CoreGraphics
import ImageIO
import MetalKit
import ModelIO
import UniformTypeIdentifiers

public extension MTLTexture {
    func toCGImage() throws -> CGImage {
        // TODO: Hack
        assert(self.pixelFormat == .rgba8Unorm || self.pixelFormat == .bgra8Unorm_srgb)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
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

#if canImport(AppKit)
public extension URL {
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}
#endif

extension MTKMesh {
    static func teapot() -> MTKMesh {
        do {
            let device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
            let teapotURL = Bundle.module.url(forResource: "teapot", withExtension: "obj")
            let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
            let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }
}

extension MTKMesh {
    static func unitSphere(inwardNormals: Bool = false) -> MTKMesh {
        do {
            let device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(sphereWithExtent: [1, 1, 1], segments: [48, 48], inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }
}
