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
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.storeAction = .store




        let root = content.environment(
            \.renderPassDescriptor, renderPassDescriptor)
//        print(content)
//        print(root)

        let graph = Graph(content: root)
        graph.rebuildIfNeeded()
        graph.dump()

        graph.root.visit { node in
            node.renderPass?._setup(node)
        }

        //        var visitor = Visitor(device: device)
        //
        //            visitor.insert(.renderPassDescriptor(renderPassDescriptor))
        //
        //            return try device.withCommandQueue(label: "􀐛OffscreenRenderer.commandQueue") { commandQueue in
        //                try commandQueue.withCommandBuffer(completion: .commitAndWaitUntilCompleted, label: "􀐛OffscreenRenderer.commandBuffer", debugGroup: "􀯕OffscreenRenderer.render()") { commandBuffer in
        //                    visitor.insert(.commandBuffer(commandBuffer))
        //                    try content.visit(visitor: &visitor)
        //                }
        //                return .init(texture: colorTexture)
        //            }

        fatalError()
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

extension EnvironmentValues {
    @Entry
    var renderPassDescriptor: MTLRenderPassDescriptor?
}

struct EnvironmentDumper: RenderPass, BuiltinRenderPass {
    @Environment(\.self)
    var environment

    func _buildNodeTree(_ parent: Node) {
        print(environment)
    }

}

extension Node {
    func visit(visitor: (Node) throws -> Void) rethrows {
        try visitor(self)
        try children.forEach { child in
            try child.visit(visitor: visitor)
        }
    }
}
