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

    func workloadEnter(_ node: Node) throws {
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

// MARK: -

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
