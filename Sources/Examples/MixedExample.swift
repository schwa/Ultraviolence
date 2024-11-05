internal import UltraviolenceSupport
import Metal
import simd
import SwiftUI
import Ultraviolence

public struct MixedExample: RenderPass {
    var size: CGSize
    var geometries: [Geometry]
    var color: MTLTexture
    var depth: MTLTexture
    var camera = SIMD3<Float>([0, 2, 6])
    var model = simd_float4x4(yRotation: .degrees(0))

    public init(size: CGSize, geometries: [Geometry], color: MTLTexture, depth: MTLTexture, camera: SIMD3<Float>, model: simd_float4x4) {
        self.size = size
        self.geometries = geometries
        self.color = color
        self.depth = depth
        self.camera = camera
        self.model = model
    }

    public var body: some RenderPass {
        get throws {
            let view = simd_float4x4(translation: camera).inverse
            return Chain {
                Render {
                    TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: model, view: view, cameraPosition: camera)
                    .colorAttachment(color, index: 0)
                    .depthAttachment(depth)
                    .depthCompare(.less)
                }
                
                Compute(threads: .init(width: Int(size.width), height: Int(size.height), depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1)) {
                    EdgeDetectionKernel()
                }
                .argument(type: .kernel, name: "depth", value: depth)
                .argument(type: .kernel, name: "color", value: color)
            }
        }
    }
}
