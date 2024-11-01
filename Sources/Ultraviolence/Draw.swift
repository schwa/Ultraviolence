import Metal
import MetalKit

public struct Draw <Content: RenderPass>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var geometry: [Geometry]
    var content: Content

    public init(_ geometry: [Geometry], @RenderPassBuilder content: () throws -> Content) throws {
        self.geometry = geometry
        self.content = try content()
    }

    public func render(_ state: inout RenderState) throws {
        let device = state.encoder.device
        try content.render(&state)
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: state.pipelineDescriptor, options: [.bindingInfo])
        guard let reflection else {
            fatalError("No reflection.")
        }
        state.encoder.setRenderPipelineState(renderPipelineState)
        for element in geometry {
            let arguments = state.argumentsStack.flatMap { $0 }
            for argument in arguments {
                switch argument.functionType {
                // TODO: Logic for .fragment and .vertex are almost identical.
                case .fragment:
                    guard let binding = reflection.fragmentBindings.first(where: { $0.name == argument.name }) else {
                        fatalError("Could not find binding for \"\(argument.name)\".")
                    }
                    switch argument.value {
                    case .float3, .float4, .matrix4x4:
                        withUnsafeBytes(of: argument.value) { buffer in
                            state.encoder.setFragmentBytes(buffer.baseAddress!, length: buffer.count, index: binding.index)
                        }
                    }
                case .vertex:
                    guard let binding = reflection.vertexBindings.first(where: { $0.name == argument.name }) else {
                        fatalError("Could not find binding for \"\(argument.name)\".")
                    }
                    switch argument.value {
                    case .float3, .float4, .matrix4x4:
                        withUnsafeBytes(of: argument.value) { buffer in
                            state.encoder.setVertexBytes(buffer.baseAddress!, length: buffer.count, index: binding.index)
                        }
                    }
                default:
                    fatalError()
                }
            }

            switch try element.mesh() {
            case .simple(let vertices):
                vertices.withUnsafeBytes { buffer in
                    // TODO: Hardcoded index = 0
                    state.encoder.setVertexBytes(buffer.baseAddress!, length: buffer.count, index: 0)
                }
                state.encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
            case .mtkMesh(let mtkMesh):
                // TODO: Verify vertex shader vertex descriptor matches mesh vertex descriptor.
                for submesh in mtkMesh.submeshes {
                    for (index, vertexBuffer) in mtkMesh.vertexBuffers.enumerated() {
                        state.encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
                    }
                    state.encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
                }
            }
        }
    }
}

