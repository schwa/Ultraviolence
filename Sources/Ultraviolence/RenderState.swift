import Metal

public struct RenderState {
    public var encoder: MTLRenderCommandEncoder
    public var pipelineDescriptor: MTLRenderPipelineDescriptor
    public var argumentsStack: [[Argument]] = []

    public init(encoder: MTLRenderCommandEncoder, pipelineDescriptor: MTLRenderPipelineDescriptor) {
        self.encoder = encoder
        self.pipelineDescriptor = pipelineDescriptor
    }
}

public struct Argument {
    public var functionType: MTLFunctionType
    public var name: String
    public var binding: Int = -1
    public var value: Value
}

public enum Value {
    case float4(SIMD4<Float>)
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
        return self.argument(type: type, name: name, value: .float4(value))
    }
}

