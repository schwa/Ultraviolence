import Metal
import simd

public struct Visitor {
    public var device: MTLDevice
    public var argumentsStack: [[Argument]]
    public var environment: [[VisitorState]]

    public init(device: MTLDevice) {
        self.device = device
        self.argumentsStack = []
        self.environment = [[]]
    }

    private mutating func push(_ state: [VisitorState]) {
        environment.append(state)
    }

    private mutating func pop() {
        environment.removeLast()
    }

    public mutating func with<R>(_ state: [VisitorState], _ body: (inout Self) throws -> R) rethrows -> R {
        push(state)
        defer {
            pop()
        }
        return try body(&self)
    }

    public mutating func insert(_ state: VisitorState) {
        environment[environment.count - 1].append(state)
    }

    private var logDepth: Int = 0

    mutating func log<R>(label: String, body: (inout Self) throws -> R) rethrows -> R {
        //        let prefix = String(repeating: "  ", count: logDepth)
        //        logger?.log("\(prefix)ENTER \(label)")
        defer {
            //            logger?.log("\(prefix)EXIT \(label)")
            logDepth -= 1
        }
        logDepth += 1
        return try body(&self)
    }
}

public enum VisitorState {
    case commandQueue(MTLCommandQueue)
    case commandBuffer(MTLCommandBuffer) // TODO: Deprecate
    case renderEncoder(MTLRenderCommandEncoder)  // TODO: Deprecate
    case renderPipelineDescriptor(MTLRenderPipelineDescriptor)
    case depthStencilDescriptor(MTLDepthStencilDescriptor)
    //    case arguments([Argument])
    case function(MTLFunction)
    //    case computePipelineDescriptor(MTLComputePipelineDescriptor)
    case depthAttachment(MTLTexture)
    case colorAttachment(MTLTexture, Int)
    case renderPassDescriptor(MTLRenderPassDescriptor)
    case logState(MTLLogState)
}

// TODO: This is a temporary solution.

public extension Visitor {
    var commandQueue: MTLCommandQueue? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .commandQueue(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    var commandBuffer: MTLCommandBuffer? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .commandBuffer(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    var renderPassDescriptor: MTLRenderPassDescriptor? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .renderPassDescriptor(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    var renderCommandEncoder: MTLRenderCommandEncoder? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .renderEncoder(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    var renderPipelineDescriptor: MTLRenderPipelineDescriptor? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .renderPipelineDescriptor(value) = element {
                    return value
                }
            }
        }
        return nil
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

    func function(type: MTLFunctionType) -> MTLFunction? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .function(value) = element {
                    if value.functionType == type {
                        return value
                    }
                }
            }
        }
        return nil
    }

    //    var computePipelineDescriptor: MTLComputePipelineDescriptor {
    //        for elements in environment.reversed() {
    //            for element in elements {
    //                if case let .computePipelineDescriptor(value) = element {
    //                    return value
    //                }
    //            }
    //        }
    //        return nil
    //    }

    var logState: MTLLogState? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .logState(value) = element {
                    return value
                }
            }
        }
        return nil
    }
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
