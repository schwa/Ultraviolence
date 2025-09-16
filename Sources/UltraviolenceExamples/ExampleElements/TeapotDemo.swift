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
        mesh = try MTKMesh.teapot()
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
