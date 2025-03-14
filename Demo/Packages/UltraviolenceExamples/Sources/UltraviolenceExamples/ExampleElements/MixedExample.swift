import Metal
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

public struct MixedExample: Element {
    var modelMatrix: simd_float4x4
    var color: SIMD3<Float>
    var lightDirection: SIMD3<Float>

    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    public init(modelMatrix: simd_float4x4, color: SIMD3<Float>, lightDirection: SIMD3<Float>) {
        self.modelMatrix = modelMatrix
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
            let colorTexture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.undefined)
            let depthTexture = try renderPassDescriptor.depthAttachment.texture.orThrow(.undefined)

            try RenderPass {
                try TeapotDemo(modelMatrix: modelMatrix, color: color, lightDirection: lightDirection)
                    // TODO: #136 Next two lines are only needed for the offscreen examples?
                    .colorAttachment0(colorTexture, index: 0)
                    .depthAttachment(depthTexture)
            }
            .renderPassDescriptorModifier { renderPassDescriptor in
                renderPassDescriptor.depthAttachment.storeAction = .store
            }
            try ComputePass {
                try EdgeDetectionKernel(depthTexture: depthTexture, colorTexture: colorTexture)
            }
        }
    }
}

extension MixedExample: Example {
    public static func runExample() throws -> ExampleResult {
        let size = CGSize(width: 1_600, height: 1_200)
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let element = MixedExample(modelMatrix: .identity, color: [1, 0, 0], lightDirection: [1, 1, 1])
        let texture = try offscreenRenderer.render(element).texture
        return .texture(texture)
    }
}
