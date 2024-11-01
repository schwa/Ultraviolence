import Metal
import simd

public struct RenderState {
    public var encoder: MTLRenderCommandEncoder
    public var pipelineDescriptor: MTLRenderPipelineDescriptor
    public var depthStencilDescriptor: MTLDepthStencilDescriptor

    public var argumentsStack: [[Argument]] = []

    public init(encoder: MTLRenderCommandEncoder, pipelineDescriptor: MTLRenderPipelineDescriptor, depthStencilDescriptor: MTLDepthStencilDescriptor) {
        self.encoder = encoder
        self.pipelineDescriptor = pipelineDescriptor
        self.depthStencilDescriptor = depthStencilDescriptor

    }
}

public struct Argument {
    public var functionType: MTLFunctionType
    public var name: String
    public var binding: Int = -1
    public var value: Value
}

public enum Value {
    case float3(SIMD3<Float>)
    case float4(SIMD4<Float>)
    case matrix4x4(simd_float4x4)
}

struct ArgumentsRenderPass <Content>: RenderPass where Content: RenderPass {
    typealias Body = Never

    var arguments: [Argument]
    var content: Content

    init(arguments: [Argument], @RenderPassBuilder content: () -> Content) {
        self.content = content()
        self.arguments = arguments
    }

    func render(_ state: inout RenderState) throws {
        state.argumentsStack.append(arguments)
        try content.render(&state)
    }
}

public extension RenderPass {
    func argument(type: MTLFunctionType, name: String, value: Value) -> some RenderPass {
        let argument = Argument(functionType: type, name: name, value: value)
        return ArgumentsRenderPass(arguments: [argument]) { self }
    }

    func argument(type: MTLFunctionType, name: String, value: SIMD4<Float>) -> some RenderPass {
        argument(type: type, name: name, value: .float4(value))
    }

    func argument(type: MTLFunctionType, name: String, value: SIMD3<Float>) -> some RenderPass {
        argument(type: type, name: name, value: .float3(value))
    }

    func argument(type: MTLFunctionType, name: String, value: simd_float4x4) -> some RenderPass {
        argument(type: type, name: name, value: .matrix4x4(value))
    }
}

