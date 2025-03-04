import CoreGraphics
import ImageIO
import MetalKit
import ModelIO
import UltraviolenceSupport
import UniformTypeIdentifiers

#if canImport(AppKit)
public extension URL {
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}
#endif

public extension MTKMesh {
    static func teapot() -> MTKMesh {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let teapotURL = Bundle.module.url(forResource: "teapot", withExtension: "obj")
            let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
            let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }

    static func sphere(extent: SIMD3<Float> = [1, 1, 1], inwardNormals: Bool = false) -> MTKMesh {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(sphereWithExtent: extent, segments: [48, 48], inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }
}
