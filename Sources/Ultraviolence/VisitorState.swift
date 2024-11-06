import Metal
import simd
internal import UltraviolenceSupport

// TODO: Rename
@MetaEnum
public enum VisitorState {
    // Render time
    case commandBuffer(MTLCommandBuffer)
    case renderCommandEncoder(MTLRenderCommandEncoder)

    case depthAttachment(MTLTexture)
    case colorAttachment(MTLTexture, Int)
    case vertexDescriptor(MTLVertexDescriptor)
    case logState(MTLLogState)

    // Setup time
    case renderPipelineDescriptor(MTLRenderPipelineDescriptor)
    case renderPassDescriptor(MTLRenderPassDescriptor)
    case depthStencilDescriptor(MTLDepthStencilDescriptor)
    case function(MTLFunction)
    case arguments([Argument])
}

// MARK: -

// TODO: This is a temporary solution.

public extension Visitor {
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

// MARK: -

public extension RenderPass {
    func depthStencilDescriptor(_ descriptor: MTLDepthStencilDescriptor) -> some RenderPass {
        EnvironmentRenderPass(environment: [.depthStencilDescriptor(descriptor)]) {
            self
        }
    }

    func colorAttachment(_ texture: MTLTexture, index: Int) -> some RenderPass {
        EnvironmentRenderPass(environment: [.colorAttachment(texture, index)]) {
            self
        }
    }

    func depthAttachment(_ texture: MTLTexture) -> some RenderPass {
        EnvironmentRenderPass(environment: [.depthAttachment(texture)]) {
            self
        }
    }

    func depthCompare(_ compareFunction: MTLCompareFunction) -> some RenderPass {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = compareFunction
        depthStencilDescriptor.isDepthWriteEnabled = true
        return EnvironmentRenderPass(environment: [.depthStencilDescriptor(depthStencilDescriptor)]) {
            self
        }
    }

    func vertexDescriptor(_ vertexDescriptor: MTLVertexDescriptor) -> some RenderPass {
        EnvironmentRenderPass(environment: [.vertexDescriptor(vertexDescriptor)]) {
            self
        }
    }
}
