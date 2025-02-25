import Metal
import simd
import SwiftUI
import Ultraviolence
internal import UltraviolenceSupport

public struct MixedExample: Element {
    var modelMatrix: simd_float4x4
    var color: SIMD4<Float>
    var lightDirection: SIMD3<Float>

    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    @UVEnvironment(\.drawableSize)
    var drawableSize

    public init(modelMatrix: simd_float4x4, color: SIMD4<Float>, lightDirection: SIMD3<Float>) {
        self.modelMatrix = modelMatrix
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            try RenderPass {
                // TODO: All these `orThrow` calls are ugly and we need a better way.
                let drawableSize = try drawableSize.orThrow(.missingEnvironment("drawableSize"))
                let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
                let colorTexture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.undefined)
                let depthTexture = try renderPassDescriptor.depthAttachment.texture.orThrow(.undefined)
                try TeapotDemo(drawableSize: .init(drawableSize), modelMatrix: modelMatrix, color: color, lightDirection: lightDirection)
                    .colorAttachment(colorTexture, index: 0)
                    .depthAttachment(depthTexture)
            }
            .renderPassModifier { renderPassDescriptor in
                // TODO: Not this needs to re-run on setup - see https://github.com/schwa/Ultraviolence/issues/36
                renderPassDescriptor.depthAttachment.storeAction = .store
            }
            try ComputePass {
                EnvironmentReader(keyPath: \.renderPassDescriptor) { renderPassDescriptor in
                    let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
                    let colorTexture = renderPassDescriptor.colorAttachments[0].texture.orFatalError()
                    let depthTexture = renderPassDescriptor.depthAttachment.texture.orFatalError()
                    try EdgeDetectionKernel(depthTexture: depthTexture, colorTexture: colorTexture)
                }
            }
        }
    }
}
