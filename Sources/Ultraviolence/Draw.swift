import Metal
import MetalKit
internal import UltraviolenceSupport

public struct Draw <Content: RenderPass>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void
    var content: Content

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void, @RenderPassBuilder content: () throws -> Content) throws {
        self.encodeGeometry = encodeGeometry
        self.content = try content()
    }

    public init(_ geometry: [Geometry], @RenderPassBuilder content: () throws -> Content) throws {
        try self.init(encodeGeometry: { encoder in
            for element in geometry {
                try encoder.withDebugGroup(label: "􀯕Draw.visit() element") {
                    let mesh = try element.mesh()
                    try mesh.draw(encoder: encoder)
                }
            }
        }, content: content)
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visitor.log(label: "Draw.\(#function).") { visitor in
            let device = visitor.device
            let encoder = try visitor.renderCommandEncoder.orThrow(.missingEnvironment(".renderCommandEncoder"))

            try encoder.withDebugGroup(label: "􀯕Draw.visit()") {
                try content.visit(&visitor)
                let renderPipelineDescriptor = try visitor.renderPipelineDescriptor.orThrow(.missingEnvironment(".renderPipelineDescriptor"))

                if renderPipelineDescriptor.vertexFunction == nil {
                    renderPipelineDescriptor.vertexFunction = try visitor.function(type: .vertex).orThrow(.missingEnvironment(".function(type: .vertex"))
                }
                if renderPipelineDescriptor.fragmentFunction == nil {
                    renderPipelineDescriptor.fragmentFunction = try visitor.function(type: .fragment).orThrow(.missingEnvironment(".function(type: .fragment"))
                }

                if let vertexDescriptor = visitor.vertexDescriptor {
                    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
                }
                else {
                    once(key: #uuidString()) {
                        logger?.info("Falling back to getting vertex descriptor from vertex function. Which does not take into account non-packed layouts.")
                    }
                    guard let vertexAttributes = try renderPipelineDescriptor.vertexFunction.orThrow(.resourceCreationFailure).vertexAttributes else {
                        fatalError("Cannot get vertex attributes from vertex function")
                    }
                    let vertexDescriptor = MTLVertexDescriptor(vertexAttributes: vertexAttributes)
                    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
                }

                let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
                guard let reflection else {
                    throw UltraviolenceError.resourceCreationFailure
                }
                // TODO: Move all this into the environment.
                encoder.setRenderPipelineState(renderPipelineState)
                encoder.setCullMode(.back)
                encoder.setFrontFacing(.counterClockwise)
                if let depthStencilDescriptor = visitor.depthStencilDescriptor {
                    let depthStencilState = try device.makeDepthStencilState(descriptor: depthStencilDescriptor).orThrow(.resourceCreationFailure)
                    encoder.setDepthStencilState(depthStencilState)
                }
                let arguments = visitor.arguments.compactMap { $0 }
                for argument in arguments {
                    try encoder.setArgument(argument, reflection: reflection)
                }
                try encodeGeometry(encoder)
            }
        }
    }
}
