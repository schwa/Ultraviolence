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

    public init(drawableSize: SIMD2<Float>, colorTexture: MTLTexture, depthTexture: MTLTexture, modelMatrix: simd_float4x4) {
        self.drawableSize = drawableSize
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture
        self.modelMatrix = modelMatrix
    }

    public var body: some Element {
        RenderPass {
            // swiftlint:disable:next force_try
            try! TeapotDemo(drawableSize: drawableSize, modelMatrix: modelMatrix, color: [1, 0, 0, 1], lightDirection: [-1, -2, -1])
            .colorAttachment(colorTexture, index: 0)
            .depthAttachment(depthTexture)
        }
        try! Compute {
            // swiftlint:disable:next force_try
            try! EdgeDetectionKernel(depthTexture: depthTexture, colorTexture: colorTexture)
        }
    }
}
