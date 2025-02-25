import Metal
import simd
import SwiftUI
import Ultraviolence
internal import UltraviolenceSupport

public struct MixedExample: Element {
    var drawableSize: SIMD2<Float>
    var colorTexture: MTLTexture
    var depthTexture: MTLTexture
    var modelMatrix: simd_float4x4
    var color: SIMD4<Float>
    var lightDirection: SIMD3<Float>

    public init(drawableSize: SIMD2<Float>, colorTexture: MTLTexture, depthTexture: MTLTexture, modelMatrix: simd_float4x4, color: SIMD4<Float>, lightDirection: SIMD3<Float>) {
        self.drawableSize = drawableSize
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture
        self.modelMatrix = modelMatrix
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            try RenderPass {
                try TeapotDemo(drawableSize: drawableSize, modelMatrix: modelMatrix, color: color, lightDirection: lightDirection)
                    .colorAttachment(colorTexture, index: 0)
                    .depthAttachment(depthTexture)
            }
            .renderPassModifier { renderPassDescriptor in
                renderPassDescriptor.depthAttachment.storeAction = .store
            }
            try ComputePass {
                try EdgeDetectionKernel(depthTexture: depthTexture, colorTexture: colorTexture)
            }
        }
    }
}
