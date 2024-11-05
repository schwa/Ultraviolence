import CoreGraphics
import Metal

// TODO: Make into a RenderPass called Render.
// TODO: This is a very WIP API.
// TODO: I'd like RenderView to be based on this.
public struct OffscreenRenderer <Content> where Content: RenderPass {
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
        var visitor = Visitor(device: device)
        return try visitor.log(label: "OffscreenRenderer.\(#function)") { visitor in
            //            let logStateDescriptor = MTLLogStateDescriptor()
            //            logStateDescriptor.bufferSize = 1024 * 1024 * 1024
            //            let logState = try! device.makeLogState(descriptor: logStateDescriptor)
            //            logState.addLogHandler { _, _, _, message in
            //                logger?.log("\(message)")
            //            }
            //
            //            visitor.insert(.logState(logState))

            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = colorTexture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.depthAttachment.texture = depthTexture
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.clearDepth = 1
            renderPassDescriptor.depthAttachment.storeAction = .store

            visitor.insert(.renderPassDescriptor(renderPassDescriptor))

            return try device.withCommandQueue(label: "􀐛OffscreenRenderer.commandQueue") { commandQueue in
                try commandQueue.withCommandBuffer(completion: .commitAndWaitUntilCompleted, label: "􀐛OffscreenRenderer.commandBuffer", debugGroup: "􀯕OffscreenRenderer.render()") { commandBuffer in
                    visitor.insert(.commandBuffer(commandBuffer))
                    try content.visit(&visitor)
                }
                return .init(texture: colorTexture)
            }
        }
    }
}

public extension OffscreenRenderer.Rendering {
    var cgImage: CGImage {
        var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        bitmapInfo.insert(.byteOrder32Little)
        let context = CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)!
        texture.getBytes(context.data!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        return context.makeImage()!
    }
}
