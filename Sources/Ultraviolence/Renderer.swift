import CoreGraphics
import Metal

// TODO: This is a very WIP API.
// TODO: I'd like RenderView to be based on this.
public struct Renderer <Content> where Content: RenderPass {
    public var device: MTLDevice = MTLCreateSystemDefaultDevice()!
    public var size: CGSize
    public var content: Content
    public var colorTexture: MTLTexture
    public var depthTexture: MTLTexture

    public init(size: CGSize, content: Content, colorTexture: MTLTexture, depthTexture: MTLTexture) {
        self.size = size
        self.content = content
        self.colorTexture = colorTexture
        self.depthTexture = depthTexture
    }

    // TODO: Most of this belongs on a RenderSession type API. We should be able to render multiple times with the same setup.
    public init(size: CGSize, content: Content) {
        let device = MTLCreateSystemDefaultDevice()!
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget]
        let colorTexture = device.makeTexture(descriptor: colorTextureDescriptor)!

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget]
        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!

        self.init(size: size, content: content, colorTexture: colorTexture, depthTexture: depthTexture)
    }

    public struct Rendering {
        public var texture: MTLTexture
    }

    public func render() throws -> Rendering {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = colorTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        //
        return try device.withCommandQueue(label: "􀐛Renderer.commandQueue") { commandQueue in
            try commandQueue.withCommandBuffer(completion: .commitAndWaitUntilCompleted, label: "􀐛Renderer.commandBuffer", debugGroup: "􀯕Renderer.render()") { commandBuffer in
                try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "􀐛Renderer.encoder") { encoder in
                    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorTexture.pixelFormat
                    renderPipelineDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
                    var visitor = Visitor(device: device)
                    try visitor.with([.commandBuffer(commandBuffer), .renderEncoder(encoder), .renderPipelineDescriptor(renderPipelineDescriptor)]) { visitor in
                        try content.visit(&visitor)
                    }
                }
                return .init(texture: colorTexture)
            }
        }

    }
}

extension MTLDevice {
    func withCommandQueue<R>(label: String? = nil, _ body: (MTLCommandQueue) throws -> R) throws -> R {
        let commandQueue = try makeCommandQueue().orThrow(.resourceCreationFailure)
        if let label = label {
            commandQueue.label = label
        }
        return try body(commandQueue)
    }
}

enum MTLCommandQueueCompletion {
    case none
    case commit
    case commitAndWaitUntilCompleted
}

extension MTLCommandQueue {
    func withCommandBuffer<R>(completion: MTLCommandQueueCompletion = .commit, label: String? = nil, debugGroup: String? = nil, _ body: (MTLCommandBuffer) throws -> R) throws -> R {
        let commandBuffer = try makeCommandBuffer().orThrow(.resourceCreationFailure)
        if let debugGroup {
            commandBuffer.pushDebugGroup(debugGroup)
        }
        defer {
            switch completion {
            case .none:
                break
            case .commit:
                commandBuffer.commit()
            case .commitAndWaitUntilCompleted:
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            if debugGroup != nil {
                commandBuffer.popDebugGroup()
            }
        }
        if let label = label {
            commandBuffer.label = label
        }
        return try body(commandBuffer)
    }
}

extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, label: String? = nil, debugGroup: String? = nil, _ body: (MTLRenderCommandEncoder) throws -> R) throws -> R {
        let encoder = try makeRenderCommandEncoder(descriptor: descriptor).orThrow(.resourceCreationFailure)
        if let debugGroup {
            encoder.pushDebugGroup(debugGroup)
        }
        defer {
            encoder.endEncoding()
            if debugGroup != nil {
                encoder.popDebugGroup()
            }
        }
        if let label = label {
            encoder.label = label
        }
        return try body(encoder)
    }
}

public extension Renderer.Rendering {
    var cgImage: CGImage {
        var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        bitmapInfo.insert(.byteOrder32Little)
        let context = CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)!
        texture.getBytes(context.data!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        return context.makeImage()!
    }
}

extension MTLCommandQueue {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

extension MTLCommandBuffer {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

extension MTLRenderCommandEncoder {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}
