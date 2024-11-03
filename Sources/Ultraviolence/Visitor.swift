import Metal
import simd

public struct Visitor {

    public var device: MTLDevice
    public var argumentsStack: [[Argument]] = []

    public var environment: [[VisitorState]] = []

    public init(device: MTLDevice) {
        self.device = device
    }

    private mutating func push(_ state: [VisitorState]) {
        environment.append(state)
    }

    private mutating func pop() {
        environment.removeLast()
    }

    public mutating func with<R>(_ state: [VisitorState], _ body: (inout Visitor) throws -> R) rethrows -> R{
        push(state)
        defer {
            pop()
        }
        return try body(&self)
    }

    public mutating func insert(_ state: VisitorState) {
        environment[environment.count - 1].append(state)
    }

}

public enum VisitorState {
    case commandBuffer(MTLCommandBuffer)
    case renderEncoder(MTLRenderCommandEncoder)
    case renderPipelineDescriptor(MTLRenderPipelineDescriptor)
    case depthStencilDescriptor(MTLDepthStencilDescriptor)
//    case arguments([Argument])
    case function(MTLFunction)
//    case computePipelineDescriptor(MTLComputePipelineDescriptor)
    case depthAttachment(MTLTexture)
    case colorAttachment(MTLTexture, Int)
}

// TODO: This is a temporary solution.

public extension Visitor {
    var commandBuffer: MTLCommandBuffer {
        for elements in environment.reversed() {
            for element in elements {
                if case let .commandBuffer(value) = element {
                    return value
                }
            }
        }
        fatalError()
    }

    var renderCommandEncoder: MTLRenderCommandEncoder {
        for elements in environment.reversed() {
            for element in elements {
                if case let .renderEncoder(value) = element {
                    return value
                }
            }
        }
        fatalError()
    }

    var renderPipelineDescriptor: MTLRenderPipelineDescriptor {
        for elements in environment.reversed() {
            for element in elements {
                if case let .renderPipelineDescriptor(value) = element {
                    return value
                }
            }
        }
        fatalError()
    }

    var depthStencilDescriptor: MTLDepthStencilDescriptor? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .depthStencilDescriptor(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    func function(type: MTLFunctionType) -> MTLFunction {
        for elements in environment.reversed() {
            for element in elements {
                if case let .function(value) = element {
                    if value.functionType == type {
                        return value
                    }
                }
            }
        }
        fatalError()
    }

//    var computePipelineDescriptor: MTLComputePipelineDescriptor {
//        for elements in environment.reversed() {
//            for element in elements {
//                if case let .computePipelineDescriptor(value) = element {
//                    return value
//                }
//            }
//        }
//        fatalError()
//    }

}

public extension RenderPass {

    func depthStencilDescriptor(_ descriptor: MTLDepthStencilDescriptor) -> some RenderPass {
        AnyRenderPassModifier(content: self) { visitor in
            visitor.insert(.depthStencilDescriptor(descriptor))
        }
    }


    func colorAttachment(_ texture: MTLTexture, index: Int) -> some RenderPass {
        AnyRenderPassModifier(content: self) { visitor in
            visitor.insert(.colorAttachment(texture, index))
        }
    }

    func depthAttachment(_ texture: MTLTexture) -> some RenderPass {
        AnyRenderPassModifier(content: self) { visitor in
            visitor.insert(.depthAttachment(texture))
        }
    }

    func depthCompare(_ compareFunction: MTLCompareFunction) -> some RenderPass {
        AnyRenderPassModifier(content: self) { visitor in
            let depthStencilDescriptor = MTLDepthStencilDescriptor()
            depthStencilDescriptor.depthCompareFunction = compareFunction
            depthStencilDescriptor.isDepthWriteEnabled = true
            visitor.insert(.depthStencilDescriptor(depthStencilDescriptor))
        }
    }
}
