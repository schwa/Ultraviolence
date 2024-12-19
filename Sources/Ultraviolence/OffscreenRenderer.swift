// swiftlint:disable no_empty_block

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
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        self.renderPassDescriptor = renderPassDescriptor

        commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
    }

    // TODO: Most of this belongs on a RenderSession type API. We should be able to render multiple times with the same setup.
    public init(size: CGSize) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget]
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).orThrow(.resourceCreationFailure)

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget]
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).orThrow(.resourceCreationFailure)

        try self.init(size: size, colorTexture: colorTexture, depthTexture: depthTexture)
    }

    public struct Rendering {
        public var texture: MTLTexture
    }
}

internal extension OffscreenRenderer {
    func render(_ body: (MTLRenderCommandEncoder) throws -> Void) throws -> Rendering {
        let commandBuffer = try commandQueue.makeCommandBuffer().orThrow(.resourceCreationFailure)
        let renderEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).orThrow(.resourceCreationFailure)
        defer {
            renderEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        try body(renderEncoder)
        return .init(texture: colorTexture)
    }
}

public extension OffscreenRenderer {
    @MainActor
    func render<Content>(_ content: Content) throws -> Rendering where Content: RenderPass {
        try render { encoder in
            let root = content
                .environment(\.renderPassDescriptor, renderPassDescriptor)
                .environment(\.device, device)
                .environment(\.commandQueue, commandQueue)
                .environment(\.renderCommandEncoder, encoder) // TODO: Move to render

            let graph = try Graph(content: root)
            //        graph.dump()

            try graph.visit { _, node in
                if let renderPass = node.renderPass as? any BodylessRenderPass {
                    renderPass._setup(node)
                }
            }
            enter: { node in
                if let body = node.renderPass as? any BodylessRenderPass {
                    try body.drawEnter()
                }
            }
            exit: { node in
                if let body = node.renderPass as? any BodylessRenderPass {
                    try body.drawExit()
                }
            }
        }
    }
}

public extension OffscreenRenderer.Rendering {
    var cgImage: CGImage {
        get throws {
            var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
            bitmapInfo.insert(.byteOrder32Little)
            let context = try CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue).orThrow(.resourceCreationFailure)
            let data = try context.data.orThrow(.resourceCreationFailure)
            texture.getBytes(data, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
            return try context.makeImage().orThrow(.resourceCreationFailure)
        }
    }
}
