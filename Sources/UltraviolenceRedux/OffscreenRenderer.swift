import CoreGraphics
import Metal
import UltraviolenceSupport

// TODO: Rename.
public struct OffscreenRenderer<Content> where Content: RenderPass {
    public var size: CGSize
    public var content: Content
    public var colorTexture: MTLTexture
    public var depthTexture: MTLTexture

    public init(
        size: CGSize, content: Content, colorTexture: MTLTexture,
        depthTexture: MTLTexture
    ) {
        self.size = size
        self.content = content
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture
    }

    // TODO: Most of this belongs on a RenderSession type API. We should be able to render multiple times with the same setup.
    public init(size: CGSize, content: Content) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(
            .resourceCreationFailure)
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb, width: Int(size.width),
            height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget]
        let colorTexture = try device.makeTexture(
            descriptor: colorTextureDescriptor
        ).orThrow(.resourceCreationFailure)

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float, width: Int(size.width),
            height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget]
        let depthTexture = try device.makeTexture(
            descriptor: depthTextureDescriptor
        ).orThrow(.resourceCreationFailure)

        self.init(
            size: size, content: content, colorTexture: colorTexture,
            depthTexture: depthTexture)
    }

    public struct Rendering {
        public var texture: MTLTexture
    }

    @MainActor
    public func render() throws -> Rendering {
        let device = try MTLCreateSystemDefaultDevice().orThrow(
            .resourceCreationFailure)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = colorTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.storeAction = .dontCare

        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let root = content
            .environment(\.renderPassDescriptor, renderPassDescriptor)
            .environment(\.device, device)
            .environment(\.commandQueue, commandQueue)
            .environment(\.commandBuffer, commandBuffer)

        let graph = Graph(content: root)
//        graph.dump()

        graph.visit { _, node in
            if let renderPass = node.renderPass as? any BodylessRenderPass {
                renderPass._setup(node)
            }
        }
        enter: { node in
            if let body = node.renderPass as? any BodylessRenderPass {
                body.drawEnter()
            }
            print(">")
        }
        exit: { node in
            print("<")
            if let body = node.renderPass as? any BodylessRenderPass {
                body.drawExit()
            }
        }

        fatalError("Not implemented.")
    }
}

extension OffscreenRenderer.Rendering {
    public var cgImage: CGImage {
        get throws {
            var bitmapInfo = CGBitmapInfo(
                rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
            bitmapInfo.insert(.byteOrder32Little)
            let context = try CGContext(
                data: nil, width: texture.width, height: texture.height,
                bitsPerComponent: 8, bytesPerRow: texture.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue
            ).orThrow(.resourceCreationFailure)
            let data = try context.data.orThrow(.resourceCreationFailure)
            texture.getBytes(
                data, bytesPerRow: texture.width * 4,
                from: MTLRegionMake2D(0, 0, texture.width, texture.height),
                mipmapLevel: 0)
            return try context.makeImage().orThrow(.resourceCreationFailure)
        }
    }
}

struct EnvironmentDumper: RenderPass, BodylessRenderPass {
    @Environment(\.self)
    var environment

    func _expandNode(_ node: Node) {
        print(environment)
    }
}

extension Graph {
    @MainActor
    func visit(_ visitor: (Int, Node) throws -> Void, enter: (Node) -> Void = { _ in }, exit: (Node) -> Void = { _ in }) rethrows {
        let saved = Graph.current
        Graph.current = self
        defer {
            Graph.current = saved
        }

        root.rebuildIfNeeded()

        assert(activeNodeStack.isEmpty)

//        { depth, node in
//            activeNodeStack.append(node)
//            defer {
//                activeNodeStack.removeLast()
//            }
//            try visitor(depth, node)

        try root.visit(visitor, enter: { node in
            activeNodeStack.append(node)
            enter(node)
        }, exit: { node in
            exit(node)
            activeNodeStack.removeLast()
        })
    }
}

extension Node {
    func visit(depth: Int = 0, _ visitor: (Int, Node) throws -> Void, enter: (Node) -> Void = { _ in }, exit: (Node) -> Void = { _ in }) rethrows {
        enter(self)
        try visitor(depth, self)
        try children.forEach { child in
            try child.visit(depth: depth + 1, visitor, enter: enter, exit: exit)
        }
        exit(self)
    }
}
