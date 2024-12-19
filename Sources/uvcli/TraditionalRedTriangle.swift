import CoreGraphics
import ImageIO
import Metal
import simd
import UniformTypeIdentifiers

// Render a red triangle using Metal _without_ using any external libraries.
enum TraditionalRedTriangle {
    // swiftlint:disable:next function_body_length
    static func main() throws {
        // Normally you'd keep the shader in a .metal file, but for the purposes of this example. The shader code is written in Metal Shading Language, which is a subset of C++. This code runs directly on the GPU.
        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float2 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        // This is the vertex shader. It takes your vertex data and transform it into a position in 'clip space'. All we're doing here is taking our 2D points and converting them into 4D vertices.
        [[vertex]] VertexOut vertex_main(
            const VertexIn in [[stage_in]]
        ) {
            VertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            return out;
        }

        // This is the fragment shader. You can think of this as a function to return a colour value for a particular pixel. We're just returning a color that has been passed into the shader from the CPU.
        [[fragment]] float4 fragment_main(
            VertexOut in [[stage_in]],
            constant float4 &color [[buffer(0)]]
        ) {
            return color;
        }
        """
        // "8-bit normalized unsigned integer components in BGRA order"
        let pixelFormat = MTLPixelFormat.bgra8Unorm
        let device = MTLCreateSystemDefaultDevice()!
        // Start by loading our shaders...
        let library = try device.makeLibrary(source: source, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!
        // And agreeing on a description of the vertices we're going to use. For simple use cases we could generate a vertex descriptor from the vertex functions 'vertexAttributes' property.
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.size
        // Define our pipeline - we're teling metal to use our shaders, our vertex descript and we're going to use color attachment 0 (other color attachments have an undefined pixel format). You can use up to 8 color attachments/or "color render targets" - see https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        // Now we take everything we've described above and produce a pipeline state object from it. We're also building a reflection object which we can use to find out how to provide data to our shaders.
        let (pipelineState, reflection) = try device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: .bindingInfo)
        // Describe and create a texture to render to. This will the color attachment 0 we mentioned above. It will be a render target to we need to mark the usage appropriately.
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: 1_600, height: 1_200, mipmapped: false)
        textureDescriptor.usage = [.renderTarget]
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        // Now we're slmost in the business of actually rendering something. We render to Metal by enqueing commands to it. The queue is usually a long lived object, while buffers generally aren't.
        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!

        // We need to make a "pass encoder" to take our commands and encode them on the command buffer. There are various types of encoders, but we're using a render encoder here - we want to render some pixels.
        let renderPassDescriptor = MTLRenderPassDescriptor()
        // We need to describe the color attachment in more detail, including the texture we're going to render to, what to do with the texture before rendering (clear it to transparent pixels), and what to do with it after rendering.
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        // Now we have a render encoder we can tell it about our pipeline that we created earlier.
        renderEncoder.setRenderPipelineState(pipelineState)
        // Now we need to encode what we're going to be drawing. We're drawing a triangle, so we need to provide the vertices of the triangle.
        let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
        // Note: We're showing how find bindings by name here, but you could hard code the binding indices if you wanted.
        let verticesIndex = reflection!.vertexBindings.first { $0.name == "vertexBuffer.0" }!.index
        renderEncoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: verticesIndex)
        // We also need to provide the color of the triangle. This gets passed directly to the fragment shader as a "uniform" value (it's uniform for every pixel we're rendering)
        var color: SIMD4<Float> = [1, 0, 0, 1]
        // Again look up the binding index by name. This is the color parameter of the fragment shader shown above.
        let colorIndex = reflection!.fragmentBindings.first { $0.name == "color" }!.index
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: colorIndex)
        // And now we encode the actual drawing of the triangle - using the vertex data we set earlier.
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        // That's it for our encoding. You'll like have more complex scenes, with multiple draw calls per encoder, and multiple encoders per command buffer.
        renderEncoder.endEncoding()
        // Tell the buffer to commit the commands we've encoded to the GPU.
        commandBuffer.commit()
        // But we want to wait for everything to finish before we read the texture data back.
        commandBuffer.waitUntilCompleted()
        // The rest of the code isn't Metal specific, but of course the above code is useless without it.
        // This bitmap info matches the specific pixel format we useded to create the texture.
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        // Let's create a venerable CGBitmapContext so we can write the pixels to a file.
        let context = CGContext(data: nil, width: texture.width, height: texture.height, bitsPerComponent: 8, bytesPerRow: texture.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)!
        // Copy the pixels out of the texture and into the bitmap context's data.
        texture.getBytes(context.data!, bytesPerRow: texture.width * 4, from: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0)
        // Create a CGImage and write it to disk.
        let image = context.makeImage()!
        let imageDestination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "output.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
}
