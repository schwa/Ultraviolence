import Metal
import QuartzCore
import UltraviolenceSupport

public extension UVEnvironmentValues {
    @UVEntry var device: MTLDevice?
    @UVEntry var commandQueue: MTLCommandQueue?
    @UVEntry var commandBuffer: MTLCommandBuffer?
    @UVEntry var renderCommandEncoder: MTLRenderCommandEncoder?
    @UVEntry var renderPassDescriptor: MTLRenderPassDescriptor?
    @UVEntry var renderPipelineState: MTLRenderPipelineState?
    @UVEntry var vertexDescriptor: MTLVertexDescriptor?
    @UVEntry var depthStencilDescriptor: MTLDepthStencilDescriptor?
    @UVEntry var depthStencilState: MTLDepthStencilState?
    @UVEntry var computeCommandEncoder: MTLComputeCommandEncoder?
    @UVEntry var computePipelineState: MTLComputePipelineState?
    @UVEntry var reflection: Reflection?
    // TODO: Investigate deprecation
    @UVEntry var colorAttachment0: (MTLTexture, Int)?
    // TODO: Investigate deprecation
    @UVEntry var depthAttachment: MTLTexture?
    @UVEntry var currentDrawable: CAMetalDrawable?
    @UVEntry var drawableSize: CGSize?
    @UVEntry var blitCommandEncoder: MTLBlitCommandEncoder?
}

public extension Element {
    func colorAttachment0(_ texture: MTLTexture, index: Int) -> some Element {
        environment(\.colorAttachment0, (texture, index))
    }
    func depthAttachment(_ texture: MTLTexture) -> some Element {
        environment(\.depthAttachment, texture)
    }
}

public extension Element {
    func vertexDescriptor(_ vertexDescriptor: MTLVertexDescriptor) -> some Element {
        environment(\.vertexDescriptor, vertexDescriptor)
    }

    func depthStencilDescriptor(_ depthStencilDescriptor: MTLDepthStencilDescriptor) -> some Element {
        environment(\.depthStencilDescriptor, depthStencilDescriptor)
    }

    func depthCompare(function: MTLCompareFunction, enabled: Bool) -> some Element {
        depthStencilDescriptor(.init(depthCompareFunction: function, isDepthWriteEnabled: enabled))
    }
}
