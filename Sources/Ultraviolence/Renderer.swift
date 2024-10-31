import CoreGraphics
import Metal

public struct Renderer <Content> where Content: RenderPass {

    let content: Content

    public init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    public struct Rendering {
        public var texture: MTLTexture
    }

    public func render(size: CGSize) throws -> Rendering {
        let device = MTLCreateSystemDefaultDevice()!
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        textureDescriptor.usage = [.renderTarget]
        let texture = device.makeTexture(descriptor: textureDescriptor)!

        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!


        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor


        var renderState = RenderState(encoder: encoder, pipelineDescriptor: renderPipelineDescriptor)
        try content.render(&renderState)

        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return .init(texture: texture)
    }
}

public struct RenderState {
    public var encoder: MTLRenderCommandEncoder
    public var pipelineDescriptor: MTLRenderPipelineDescriptor
}

public extension Renderer.Rendering {
    var cgImage: CGImage {

        var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        bitmapInfo.insert(.byteOrder32Little)
        let context = CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)!
        texture.getBytes(context.data!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        return context.makeImage()!
    }
}

