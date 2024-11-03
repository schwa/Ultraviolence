import CoreGraphics
import Metal

public struct Renderer <Content> where Content: RenderPass {

    let content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public struct Rendering {
        public var texture: MTLTexture
    }

    public func render(size: CGSize) throws -> Rendering {
        let device = MTLCreateSystemDefaultDevice()!
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget]
        let colorTexture = device.makeTexture(descriptor: colorTextureDescriptor)!

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget]
        let depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)!

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
        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorTexture.pixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
        var visitor = Visitor(device: device)
        visitor.with([.commandBuffer(commandBuffer), .renderEncoder(encoder), .renderPipelineDescriptor(renderPipelineDescriptor)]) { visitor in
            try! content.visit(&visitor)
        }
        encoder.endEncoding()
        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
        return .init(texture: colorTexture)
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

