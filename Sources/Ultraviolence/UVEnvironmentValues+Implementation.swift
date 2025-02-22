import Metal
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
    @UVEntry var colorAttachment: (MTLTexture, Int)?
    @UVEntry var depthAttachment: MTLTexture?
}

public extension Element {
    func colorAttachment(_ texture: MTLTexture, index: Int) -> some Element {
        environment(\.colorAttachment, (texture, index))
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
