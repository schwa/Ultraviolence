import Metal
import UltraviolenceSupport

public struct CommandBufferElement <Content>: Element, BodylessContentElement where Content: Element {
    // @UVEnvironment(\.enableMetalLogging)
    // var enableMetalLogging

    var completion: MTLCommandQueueCompletion
    var content: Content

    public init(completion: MTLCommandQueueCompletion, @ElementBuilder content: () throws -> Content) rethrows {
        self.completion = completion
        self.content = try content()
    }

    func system_workloadEnter(_ node: NeoNode) throws {
        let commandQueue = try node.environmentValues.commandQueue.orThrow(.missingEnvironment(\.commandQueue))
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        // TODO: #97 Users cannot modify the environment here. This is a problem.
        //        if enableMetalLogging {
        //            print("ENABLING LOGGING")
        //            try commandBufferDescriptor.addDefaultLogging()
        //        }
        // TODO: #98 There isn't an opportunity to modify the descriptor here.
        let commandBuffer = try commandQueue._makeCommandBuffer(descriptor: commandBufferDescriptor)
        node.environmentValues.commandBuffer = commandBuffer
    }

    func system_workloadExit(_ node: NeoNode) throws {
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

// MARK: -

public extension Element {
    func onCommandBufferScheduled(_ action: @escaping (MTLCommandBuffer) -> Void) -> some Element {
        EnvironmentReader(keyPath: \.commandBuffer) { commandBuffer in
            // Copy action into a nonisolated(unsafe) local so the @Sendable closure can capture it safely.
            nonisolated(unsafe) let actionCopy = action
            return self.onWorkloadEnter { _ in
                if let commandBuffer {
                    commandBuffer.addScheduledHandler { commandBuffer in
                        actionCopy(commandBuffer)
                    }
                }
            }
        }
    }

    func onCommandBufferCompleted(_ action: @escaping (MTLCommandBuffer) -> Void) -> some Element {
        EnvironmentReader(keyPath: \.commandBuffer) { commandBuffer in
            // Copy action into a nonisolated(unsafe) local so the @Sendable closure can capture it safely.
            nonisolated(unsafe) let actionCopy = action
            return self.onWorkloadEnter { _ in
                if let commandBuffer {
                    commandBuffer.addCompletedHandler { commandBuffer in
                        actionCopy(commandBuffer)
                    }
                }
            }
        }
    }
}
