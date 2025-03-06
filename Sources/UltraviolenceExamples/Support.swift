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
    convenience init(name: String, bundle: Bundle) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let teapotURL = bundle.url(forResource: name, withExtension: "obj")
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.stride * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.stride * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.stride * 8)
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: vertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
        try self.init(mesh: mdlMesh, device: device)
    }


    static func teapot() -> MTKMesh {
        do {
            return try MTKMesh(name: "teapot", bundle: .module)
//            let device = _MTLCreateSystemDefaultDevice()
//            let teapotURL = Bundle.module.url(forResource: "teapot", withExtension: "obj")
//            let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
//            let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
//            return try MTKMesh(mesh: mdlMesh, device: device)
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

    static func plane(width: Float = 1, height: Float = 1, segments: SIMD2<UInt32> = [2, 2]) -> MTKMesh {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(planeWithExtent: [width, height, 0], segments: segments, geometryType: .triangles, allocator: allocator)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }
}
