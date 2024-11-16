import CoreGraphics
import ImageIO
import Metal
import simd
import UniformTypeIdentifiers

enum BasicRedTriangle {
    static func main() throws {
        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float2 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        [[vertex]] VertexOut vertex_main(
            const VertexIn in [[stage_in]]
        ) {
            VertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            return out;
        }

        [[fragment]] float4 fragment_main(
            VertexOut in [[stage_in]],
            constant float4 &color [[buffer(0)]]
        ) {
            return color;
        }
        """
        let pixelFormat = MTLPixelFormat.bgra8Unorm
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.size
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: 1_600, height: 1_200, mipmapped: false)
        textureDescriptor.usage = [.renderTarget]
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        let (pipelineState, reflection) = try device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: .bindingInfo)
        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        let vertices: [SIMD2<Float>] = [[0, 0.5], [-0.5, -0.5], [0.5, -0.5]]
        let verticesIndex = reflection!.vertexBindings.first { $0.name == "vertexBuffer.0" }!.index
        renderEncoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: verticesIndex)
        var color: SIMD4<Float> = [1, 0, 0, 1]
        let colorIndex = reflection!.fragmentBindings.first { $0.name == "color" }!.index
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: colorIndex)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        let context = CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue
        )!
        texture.getBytes(context.data!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        let image = context.makeImage()!
        let imageDestination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "output.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
}
