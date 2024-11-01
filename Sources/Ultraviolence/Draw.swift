import Metal

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
            let triangles = element.vertices(for: .triangle)
            let arguments = state.argumentsStack.flatMap { $0 }
            for argument in arguments {
                switch argument.functionType {
                case .fragment:
                    guard let binding = reflection.fragmentBindings.first(where: { $0.name == argument.name }) else {
                        fatalError("Could not find binding for \"\(argument.name)\".")
                    }
                    switch argument.value {
                    case .float4(let value):
                        withUnsafeBytes(of: value) { buffer in
                            state.encoder.setFragmentBytes(buffer.baseAddress!, length: buffer.count, index: binding.index)
                        }
                    }
                default:
                    fatalError()
                }
            }

            triangles.withUnsafeBytes { buffer in
                // TODO: Hardcoded index = 0
                state.encoder.setVertexBytes(buffer.baseAddress!, length: buffer.count, index: 0)
            }
            state.encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangles.count)
        }
    }
}

