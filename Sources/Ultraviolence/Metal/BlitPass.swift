import Metal

public struct BlitPass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func workloadEnter(_ node: Node) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let blitCommandEncoder = try commandBuffer._makeBlitCommandEncoder()
        node.environmentValues.blitCommandEncoder = blitCommandEncoder
    }

    func workloadExit(_ node: Node) throws {
        let blitCommandEncoder = try node.environmentValues.blitCommandEncoder.orThrow(.missingEnvironment(\.blitCommandEncoder))
        blitCommandEncoder.endEncoding()
    }
}

public struct Blit: Element, BodylessElement {
    var block: (MTLBlitCommandEncoder) throws -> Void

    public init(_ block: @escaping (MTLBlitCommandEncoder) throws -> Void) {
        self.block = block
    }

    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func workloadEnter(_ node: Node) throws {
        let blitCommandEncoder = try node.environmentValues.blitCommandEncoder.orThrow(.missingEnvironment(\.blitCommandEncoder))
        try block(blitCommandEncoder)
    }
}
