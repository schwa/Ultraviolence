import Metal
import UltraviolenceSupport

public extension EnvironmentValues {
    @Entry var device: MTLDevice?
    @Entry var commandQueue: MTLCommandQueue?
    @Entry var commandBuffer: MTLCommandBuffer?
    @Entry var renderCommandEncoder: MTLRenderCommandEncoder?
    @Entry var renderPassDescriptor: MTLRenderPassDescriptor?
    @Entry var renderPipelineState: MTLRenderPipelineState?
    @Entry var vertexDescriptor: MTLVertexDescriptor?
    @available(*, deprecated, message: "Deprecated. Use ``.reflection``.")
    @Entry var renderPipelineReflection: MTLRenderPipelineReflection?
    @Entry var depthStencilDescriptor: MTLDepthStencilDescriptor?
    @Entry var depthStencilState: MTLDepthStencilState?
    @Entry var computeCommandEncoder: MTLComputeCommandEncoder?
    @Entry var computePipelineState: MTLComputePipelineState?
    @Entry var reflection: Reflection?
    @Entry var colorAttachment: (MTLTexture, Int)?
    @Entry var depthAttachment: MTLTexture?
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
