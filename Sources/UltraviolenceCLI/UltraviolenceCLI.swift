import CoreGraphics
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport
import ModelIO
import Metal
import MetalKit
import simd
import ImageIO
import UniformTypeIdentifiers

@main
struct Main {
    static func main() async throws {
        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float3 position [[attribute(0)]];
            float3 normals [[attribute(1)]];
            float2 texcoords [[attribute(2)]];
        };

        struct VertexOut {
            float4 position [[position]];
            uint vertex_id [[flat]]; // turn off interpolation
        };

        [[vertex]] VertexOut vertex_main(
            const VertexIn in [[stage_in]],
            uint vertex_id [[vertex_id]],
            constant float4x4 &modelMatrix [[buffer(1)]],
            constant float4x4 &viewMatrix [[buffer(2)]],
            constant float4x4 &projectionMatrix [[buffer(3)]]
        ) {
            VertexOut out;
            float4x4 mvpMatrix = projectionMatrix * viewMatrix * modelMatrix;
            out.position = mvpMatrix * float4(in.position, 1.0);
            out.vertex_id = vertex_id;
            return out;
        }

        [[fragment]] uint fragment_main(
            VertexOut in [[stage_in]]
        ) {
            return in.vertex_id;
        }
        """
        let vertexShader = try VertexShader(source: source)
        let fragmentShader = try FragmentShader(source: source)

        let device = MTLCreateSystemDefaultDevice()!

        let size = CGSize(width: 1600, height: 1200)

        let colorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Uint, width: Int(size.width), height: Int(size.height), mipmapped: false)
        colorTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite] // TODO: #33 this is all hardcoded :-(
        let colorTexture = try device.makeTexture(descriptor: colorTextureDescriptor).orThrow(.textureCreationFailure)
        colorTexture.label = "Color Texture"

        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(size.width), height: Int(size.height), mipmapped: false)
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead] // TODO: #33 this is all hardcoded :-(
        let depthTexture = try device.makeTexture(descriptor: depthTextureDescriptor).orThrow(.textureCreationFailure)
        depthTexture.label = "Depth Texture"

        let teapotURL = Bundle.module.url(forResource: "Teapot", withExtension: "usdz")!
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: allocator)
        // Note with USDZ sometimes we have to dig into the object tree of the asset to find the mesh - .obj's mesh will be at root.
        let mdlMesh = try (mdlAsset.object(at: 0).children[2].children[0] as? MDLMesh).orThrow(.resourceCreationFailure("Failed to load teapot."))
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        let vertexDescriptor = MTLVertexDescriptor(mtkMesh.vertexDescriptor)

        let modelMatrix = simd_float4x4.identity
        let cameraMatrix = lookAtMatrix(eye: [0, 0, 1000], target: [0, 0, 0], up: [0, 1, 0])
        let viewMatrix = cameraMatrix.inverse
        let projectionMatrix = PerspectiveProjection().projectionMatrix(for: size)

        let texture = try MTLCaptureManager.shared().with(enabled: false) {
            let root = try RenderPass {
                try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: mtkMesh)
                        encoder.draw(mtkMesh)
                    }
                    .parameter("modelMatrix", modelMatrix)
                    .parameter("viewMatrix", viewMatrix)
                    .parameter("projectionMatrix", projectionMatrix)
                }
                .vertexDescriptor(vertexDescriptor)
            }
            let offscreenRenderer = try OffscreenRenderer(size: size, colorTexture: colorTexture, depthTexture: depthTexture)
            let texture = try offscreenRenderer.render(root).texture
            return texture
        }

        assert(texture === colorTexture)

        var values = [UInt32](repeating: 0, count: Int(size.width * size.height))
        values.withUnsafeMutableBytes { bytes in
            texture.getBytes(bytes.baseAddress!, bytesPerRow: MemoryLayout<UInt32>.stride * Int(size.width), bytesPerImage: MemoryLayout<UInt32>.stride * Int(size.width) * Int(size.height), from: MTLRegionMake2D(0, 0, Int(size.width), Int(size.height)), mipmapLevel: 0, slice: 0)
        }
        print(values)
    }
}
