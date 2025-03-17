import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

/// A demo that shows the use of a stencil texture.
/// This view creates a texture, the size of the output drawable, containing a checkerboard pattern. The texture is regenerated when the drawable size changes.
/// During the render loop it blits the checkerboard texture into the stencil attachment of the render pass descriptor. A better way would be to just set the stencil attachment storeAction to .store but that is too easy for this demo.
/// It then enables the stencil test and draws a triangle. The resulting triangle should be clipped by the stencil texture.
public struct StencilDemoView: View {
    let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]]
    ) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant float4 &color [[buffer(0)]]
    ) {
        return color;
    }
    """

    @State
    private var texture: MTLTexture?

    let depthStencilDescriptor: MTLDepthStencilDescriptor = {
        let stencilDescriptor = MTLStencilDescriptor(compareFunction: .equal, readMask: 0xFF, writeMask: 0x00)
        return MTLDepthStencilDescriptor(depthCompareFunction: .always, isDepthWriteEnabled: false, frontFaceStencil: stencilDescriptor, backFaceStencil: stencilDescriptor)
    }()

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        RenderView {
            try BlitPass {
                EnvironmentReader(keyPath: \.renderPassDescriptor) { renderPassDescriptor in
                    let stencilAttachmentTexture = renderPassDescriptor!.stencilAttachment.texture!
                    Blit { encoder in
                        encoder.copy(from: try texture.orThrow(.resourceCreationFailure("texture")), sourceSlice: 0, sourceLevel: 0, sourceOrigin: .init(x: 0, y: 0, z: 0), sourceSize: .init(width: texture!.width, height: texture!.height, depth: 1), to: stencilAttachmentTexture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: .init(x: 0, y: 0, z: 0))
                    }
                }
            }
            try RenderPass {
                let vertexShader = try VertexShader(source: source)
                let fragmentShader = try FragmentShader(source: source)
                try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                    Draw { encoder in
                        let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                        encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                    }
                    .parameter("color", [0.5, 1, 0.5, 1])
                }
                .depthStencilDescriptor(depthStencilDescriptor)
            }
            .renderPassDescriptorModifier { renderPassDescriptor in
                renderPassDescriptor.stencilAttachment.loadAction = .load
            }
        }
        .metalClearColor(.init(red: 0.1, green: 0.2, blue: 0.1, alpha: 1.0))
        .metalDepthStencilPixelFormat(.stencil8)
        .metalDepthStencilAttachmentTextureUsage([.shaderWrite, .renderTarget])
        .onDrawableSizeChange { size in
            do {
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Uint, width: Int(size.width), height: Int(size.height), mipmapped: false)
                descriptor.usage = [.shaderRead, .shaderWrite]

                let device = _MTLCreateSystemDefaultDevice()
                let texture = device.makeTexture(descriptor: descriptor)!
                texture.label = "Faux Stencil Texture"
                let pass = try ComputePass {
                    try CheckerboardKernel_ushort(outputTexture: texture, checkerSize: [100, 100], foregroundColor: 0xFFFF)
                }
                try pass.run()
                self.texture = texture
            }
            catch {
                fatalError("\(error)")
            }
        }
    }
}

extension StencilDemoView: DemoView {
}
