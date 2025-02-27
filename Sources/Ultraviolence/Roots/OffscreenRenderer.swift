import CoreGraphics
import Metal
import UltraviolenceSupport

// TODO: Rename.
public struct OffscreenRenderer {
    public var device: MTLDevice
    public var size: CGSize
    public var colorTexture: MTLTexture
    public var depthTexture: MTLTexture
    public var renderPassDescriptor: MTLRenderPassDescriptor
    public var commandQueue: MTLCommandQueue

    public init(size: CGSize, colorTexture: MTLTexture, depthTexture: MTLTexture) throws {
        self.device = colorTexture.device
        self.size = size
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = colorTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.storeAction = .store // TODO: This is hardcoded. Should usually be .dontCare but we need to read back in some examples. https://github.com/schwa/Ultraviolence/issues/33
        self.renderPassDescriptor = renderPassDescriptor

        commandQueue = try device._makeCommandQueue()
    }

    // TODO: Most of this belongs on a RenderSession type API. We should be able to render multiple times with the same setup. https://github.com/schwa/Ultraviolence/issues/28
    public init(size: CGSize) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite] // TODO: this is all hardcoded :-( https://github.com/schwa/Ultraviolence/issues/33
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).orThrow(.textureCreationFailure)
        colorTexture.label = "Color Texture"

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead] // TODO: this is all hardcoded :-( https://github.com/schwa/Ultraviolence/issues/33
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).orThrow(.textureCreationFailure)
        depthTexture.label = "Depth Texture"

        try self.init(size: size, colorTexture: colorTexture, depthTexture: depthTexture)
    }

    public struct Rendering {
        public var texture: MTLTexture
    }
}

public extension OffscreenRenderer {
    @MainActor
    func render<Content>(_ content: Content) throws -> Rendering where Content: Element {
        let device = _MTLCreateSystemDefaultDevice()
        let commandQueue = try device._makeCommandQueue()
        let content = CommandBufferElement(completion: .commitAndWaitUntilCompleted) {
            content
        }
        .environment(\.device, device)
        .environment(\.commandQueue, commandQueue)
        .environment(\.renderPassDescriptor, renderPassDescriptor)
        .environment(\.drawableSize, size)
        let graph = try Graph(content: content)
        try graph.processSetup()
        try graph.processWorkload()
        return .init(texture: colorTexture)
    }
}

public extension OffscreenRenderer.Rendering {
    var cgImage: CGImage {
        get throws {
            try texture.toCGImage()
        }
    }
}
