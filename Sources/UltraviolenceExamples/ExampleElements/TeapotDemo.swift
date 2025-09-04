#if canImport(AppKit)
import AppKit
#endif
import CoreGraphics
import ImageIO
import Metal
import MetalKit
import ModelIO
import simd
import Ultraviolence
import UltraviolenceSupport
import UniformTypeIdentifiers

public struct TeapotDemo: Element {
    @UVState
    var mesh: MTKMesh
    var color: SIMD3<Float>
    var transforms: Transforms
    var lightDirection: SIMD3<Float>

    public init(transforms: Transforms, color: SIMD3<Float>, lightDirection: SIMD3<Float>) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let teapotURL = try Bundle.main.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure("Failed to find teapot.obj."))
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orThrow(.resourceCreationFailure("Failed to load teapot.obj."))
        mesh = try MTKMesh(mesh: mdlMesh, device: device)
        self.transforms = transforms
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            try LambertianShader(transforms: transforms, color: color, lightDirection: lightDirection) {
                Draw { encoder in
                    encoder.setVertexBuffers(of: mesh)
                    encoder.draw(mesh)
                }
            }
            .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
            .depthCompare(function: .less, enabled: true)
        }
    }
}
