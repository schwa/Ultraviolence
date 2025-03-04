import Metal
import UltraviolenceSupport

// TODO: #46 Rename. Remove element from name. "CommandBuffer" is _not_ a good name though.
public struct CommandBufferElement <Content>: Element, BodylessContentElement where Content: Element {
    var completion: MTLCommandQueueCompletion
    var content: Content

    init(completion: MTLCommandQueueCompletion, @ElementBuilder content: () throws -> Content) rethrows {
        self.completion = completion
        self.content = try content()
    }

    func workloadEnter(_ node: Node) throws {
        let commandQueue = try node.environmentValues.commandQueue.orThrow(.missingEnvironment(\.commandQueue))
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        let commandBuffer = try commandQueue._makeCommandBuffer(descriptor: commandBufferDescriptor)
        node.environmentValues.commandBuffer = commandBuffer
    }

    func workloadExit(_ node: Node) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        switch completion {
        case .none:
            break

        case .commit:
            commandBuffer.commit()

        case .commitAndWaitUntilCompleted:
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}

public extension Element {
    func onCommandBufferScheduled(_ action: @escaping (MTLCommandBuffer) -> Void) -> some Element {
        EnvironmentReader(keyPath: \.commandBuffer) { commandBuffer in
            self.onWorkloadEnter { _ in
                if let commandBuffer {
                    commandBuffer.addScheduledHandler { commandBuffer in
                        action(commandBuffer)
                    }
                }
            }
        }
    }

    func onCommandBufferCompleted(_ action: @escaping (MTLCommandBuffer) -> Void) -> some Element {
        EnvironmentReader(keyPath: \.commandBuffer) { commandBuffer in
            self.onWorkloadEnter { _ in
                if let commandBuffer {
                    commandBuffer.addCompletedHandler { commandBuffer in
                        action(commandBuffer)
                    }
                }
            }
        }
    }
}

internal struct WorkloadModifier <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var content: Content
    var _workloadEnter: ((UVEnvironmentValues) throws -> Void)?

    init(content: Content, workloadEnter: ((UVEnvironmentValues) throws -> Void)? = nil) {
        self.content = content
        self._workloadEnter = workloadEnter
    }

    func workloadEnter(_ node: Node) throws {
        try _workloadEnter?(node.environmentValues)
    }
}

public extension Element {
    func onWorkloadEnter(_ action: @escaping (UVEnvironmentValues) throws -> Void) -> some Element {
        WorkloadModifier(content: self, workloadEnter: action)
    }
}
