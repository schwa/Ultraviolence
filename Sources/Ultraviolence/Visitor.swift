import Metal
import simd

public struct Visitor {
    public var device: MTLDevice
    public var environment: [[VisitorState]]

    public init(device: MTLDevice) {
        self.device = device
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

    // TODO: Make sure all insert() usages are not better replaced with with().
    public mutating func insert(_ state: VisitorState) {
        environment[environment.count - 1].append(state)
    }

    private var logDepth: Int = 0
    static let logVisitor = ProcessInfo.processInfo.environment["LOG_VISITOR"].isTrue

    mutating func log<R>(label: String, body: (inout Self) throws -> R) rethrows -> R {
        if !Self.logVisitor {
            return try body(&self)
        }
        let prefix = String(repeating: "  ", count: logDepth)
        logger?.log("\(prefix)ENTER \(label)")
        defer {
            logger?.log("\(prefix)EXIT \(label)")
            logDepth -= 1
        }
        logDepth += 1
        return try body(&self)
    }
}

public enum VisitorState {
    case commandQueue(MTLCommandQueue)
    case commandBuffer(MTLCommandBuffer)

    case renderCommandEncoder(MTLRenderCommandEncoder)

    case renderPipelineDescriptor(MTLRenderPipelineDescriptor)
    case renderPassDescriptor(MTLRenderPassDescriptor)

    case depthStencilDescriptor(MTLDepthStencilDescriptor)
    case function(MTLFunction)
    //    case computePipelineDescriptor(MTLComputePipelineDescriptor)
    case depthAttachment(MTLTexture)
    case colorAttachment(MTLTexture, Int)
    case logState(MTLLogState)
    case vertexDescriptor(MTLVertexDescriptor)

    case arguments([Argument])
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
                if case let .renderCommandEncoder(value) = element {
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

    var vertexDescriptor: MTLVertexDescriptor? {
        for elements in environment.reversed() {
            for element in elements {
                if case let .vertexDescriptor(value) = element {
                    return value
                }
            }
        }
        return nil
    }

    var arguments: [Argument] {
        var result: [Argument] = []
        for elements in environment.reversed() {
            for element in elements {
                if case let .arguments(value) = element {
                    result.append(contentsOf: value)
                }
            }
        }
        return result
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

    func vertexDescriptor(_ descriptor: MTLVertexDescriptor) -> some RenderPass {
        AnyRenderPassModifier(content: self) { visitor in
            visitor.insert(.vertexDescriptor(descriptor))
        }
    }
}
