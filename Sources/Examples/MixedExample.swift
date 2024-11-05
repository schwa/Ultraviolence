import Metal
import simd
import SwiftUI
import Ultraviolence
internal import UltraviolenceSupport

public struct MixedExample: RenderPass {
    var size: CGSize
    var geometries: [Geometry]
    var colorTexture: MTLTexture
    var depthTexture: MTLTexture
    var camera = SIMD3<Float>([0, 2, 6])
    var model = simd_float4x4(yRotation: .degrees(0))

    public init(size: CGSize, geometries: [Geometry], colorTexture: MTLTexture, depthTexture: MTLTexture, camera: SIMD3<Float>, model: simd_float4x4) {
        self.size = size
        self.geometries = geometries
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture
        self.camera = camera
        self.model = model
    }

    public var body: some RenderPass {
        get throws {
            try Chain {
                Render {
                    let view = simd_float4x4(translation: camera).inverse
                    TeapotRenderPass(color: .red, size: size, model: model, view: view, cameraPosition: camera)
                        .colorAttachment(colorTexture, index: 0)
                        .depthAttachment(depthTexture)
                        .depthCompare(.less)
                }

                try Compute(threads: .init(width: colorTexture.width, height: colorTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1)) {
                    EdgeDetectionKernel()
                        .argument(type: .kernel, name: "depth", value: depthTexture)
                        .argument(type: .kernel, name: "color", value: colorTexture)
                }
            }
        }
    }
}
