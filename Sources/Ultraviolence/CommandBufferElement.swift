import Metal
import UltraviolenceSupport

public struct CommandBufferElement <Content>: Element, BodylessContentElement where Content: Element {
    var completion: MTLCommandQueueCompletion
    var content: Content

    init(completion: MTLCommandQueueCompletion, @ElementBuilder content: () throws -> Content) rethrows {
        self.completion = completion
        self.content = try content()
    }

    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        let device = try environment.device.orThrow(.missingEnvironment(\.commandBuffer))
        let commandQueue = try environment.commandQueue.orThrow(.missingEnvironment(\.commandBuffer))
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        let commandBuffer = try commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        environment.commandBuffer = commandBuffer
    }

    func _exit(_ node: Node, environment: UVEnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
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
