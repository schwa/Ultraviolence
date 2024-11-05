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

    public func visit(_ visitor: inout Visitor) throws {
        let device = visitor.device
        let encoder = try visitor.renderCommandEncoder.orThrow(.missingEnvironment(".renderCommandEncoder"))

        try encoder.withDebugGroup(label: "􀯕Draw.visit()") {
            try content.visit(&visitor)
            let renderPipelineDescriptor = try visitor.renderPipelineDescriptor.orThrow(.missingEnvironment(".renderPipelineDescriptor"))
            let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
            guard let reflection else {
                fatalError("No reflection.")
            }
            // TODO: Move all this into the environment.
            encoder.setRenderPipelineState(renderPipelineState)
            encoder.setCullMode(.back)
            encoder.setFrontFacing(.counterClockwise)
            if let depthStencilDescriptor = visitor.depthStencilDescriptor {
                let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
                encoder.setDepthStencilState(depthStencilState)
            }
            for element in geometry {
                try encoder.withDebugGroup(label: "􀯕Draw.visit() element") {
                    let arguments = visitor.argumentsStack.flatMap { $0 }
                    for argument in arguments {
                        try encoder.setArgument(argument, reflection: reflection)
                    }
                    let mesh = try element.mesh()
                    mesh.draw(encoder: encoder)
                }
            }
        }
    }
}

extension MTLRenderCommandEncoder {
    func setArgument(_ argument: Argument, reflection:  MTLRenderPipelineReflection) throws {
        switch argument.functionType {
        // TODO: Logic for .fragment and .vertex are almost identical.
        case .fragment:
            guard let binding = reflection.fragmentBindings.first(where: { $0.name == argument.name }) else {
                fatalError("Could not find binding for \"\(argument.name)\".")
            }
            switch argument.value {
            case .float3, .float4, .matrix4x4:
                try withUnsafeBytes(of: argument.value) { buffer in
                    let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                    setFragmentBytes(baseAddress, length: buffer.count, index: binding.index)
                }
            case .texture(let texture):
                setFragmentTexture(texture, index: binding.index)
            }
        case .vertex:
            guard let binding = reflection.vertexBindings.first(where: { $0.name == argument.name }) else {
                fatalError("Could not find binding for \"\(argument.name)\".")
            }
            switch argument.value {
            case .float3, .float4, .matrix4x4:
                try withUnsafeBytes(of: argument.value) { buffer in
                    let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                    setVertexBytes(baseAddress, length: buffer.count, index: binding.index)
                }
            case .texture(let texture):
                setVertexTexture(texture, index: binding.index)
            }
        default:
            fatalError("Not implemented")
        }
    }
}

extension Mesh {
    func draw(encoder: MTLRenderCommandEncoder) {
        switch self {
        case .simple(let vertices):
            vertices.withUnsafeBytes { buffer in
                // TODO: Hardcoded index = 0
                encoder.setVertexBytes(buffer.baseAddress!, length: buffer.count, index: 0)
            }
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        case .mtkMesh(let mtkMesh):
            // TODO: Verify vertex shader vertex descriptor matches mesh vertex descriptor.
            for submesh in mtkMesh.submeshes {
                for (index, vertexBuffer) in mtkMesh.vertexBuffers.enumerated() {
                    encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
                }
                encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
            }
        }

    }
}
