import CoreGraphics
import ImageIO
import Metal
import simd
import UltraviolenceRedux
import UniformTypeIdentifiers

enum ImprovedRedTriangle {
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
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb // TODO: Get from renderer
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float // TODO: Get from renderer
        // Now we take everything we've described above and produce a pipeline state object from it. We're also building a reflection object which we can use to find out how to provide data to our shaders.
        let (pipelineState, reflection) = try device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: .bindingInfo)

        let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))

        let rendering = try offscreenRenderer.render { renderEncoder in
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
        }

        let image = try rendering.cgImage
        let imageDestination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "output.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
}
