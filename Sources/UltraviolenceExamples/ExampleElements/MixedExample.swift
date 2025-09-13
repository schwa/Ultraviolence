import Metal
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

public struct MixedExample: Element {
    var transforms: Transforms
    var color: SIMD3<Float>
    var lightDirection: SIMD3<Float>

    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    public init(transforms: Transforms, color: SIMD3<Float>, lightDirection: SIMD3<Float>) {
        self.transforms = transforms
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
            let colorTexture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.resourceCreationFailure("Missing color attachment texture"))
            let depthTexture = try renderPassDescriptor.depthAttachment.texture.orThrow(.resourceCreationFailure("Missing depth attachment texture"))

            try RenderPass {
                try TeapotDemo(transforms: transforms, color: color, lightDirection: lightDirection)
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
