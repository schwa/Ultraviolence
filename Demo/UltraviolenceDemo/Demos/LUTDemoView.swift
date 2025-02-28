import Metal
import MetalKit
import SwiftUI
import Ultraviolence

struct LUTDemoView: View {
    @State
    private var blend: Float = 0.0

    @State
    private var sourceTexture: MTLTexture

    @State
    private var lutTexture: MTLTexture

    @State
    private var outputTexture: MTLTexture

    init() {
        let textureLoader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
        let inputTextureURL = Bundle.main.url(forResource: "DJSI3956", withExtension: "JPG")!
        let sourceTexture = try! textureLoader.newTexture(URL: inputTextureURL, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .origin: MTKTextureLoader.Origin.flippedVertically.rawValue,
            .SRGB: true
        ])
        let lutTextureURL = Bundle.main.url(forResource: "Sepia Tone", withExtension: "png")!
        let lutTexture2D = try! textureLoader.newTexture(URL: lutTextureURL, options: [
            .origin: MTKTextureLoader.Origin.topLeft.rawValue,
            .SRGB: true
        ])

        let lutTexture = try! create3DLUT(device: MTLCreateSystemDefaultDevice()!, from: lutTexture2D)!

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        let outputTexture = MTLCreateSystemDefaultDevice()!.makeTexture(descriptor: descriptor)!

        self.sourceTexture = sourceTexture
        self.lutTexture = lutTexture
        self.outputTexture = outputTexture

        print(sourceTexture.width, sourceTexture.height)
    }

    @State
    var cubeTexture: MTLTexture?

    var body: some View {
        RenderView {
            try! Group {
                try ComputePass {
                    try LUTComputePipeline(inputTexture: sourceTexture, lutTexture: lutTexture, blend: blend, outputTexture: outputTexture)
                }
                try! RenderPass {
                    try! BillboardRenderPipeline(texture: outputTexture)
                }
            }
        }
        .metalColorPixelFormat(.rgba16Float) //
        .aspectRatio(Double(sourceTexture.width) / Double(sourceTexture.height), contentMode: .fit)
        .overlay(alignment: .bottom) {
            Slider(value: $blend, in: 0...1)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding()
        }
        .task {
            let url = Bundle.main.url(forResource: "Custom_LUT", withExtension: "cube")!
            let cube = try! CubeReader(url: url)
            cubeTexture = try! cube.toTexture()
        }
    }
}

extension LUTDemoView: DemoView {
}

struct LUTComputePipeline: Element {
    let inputTexture: MTLTexture
    let lutTexture: MTLTexture
    let blend: Float
    let outputTexture: MTLTexture
    let kernel: ComputeKernel

    init(inputTexture: MTLTexture, lutTexture: MTLTexture, blend: Float, outputTexture: MTLTexture) throws {
        self.inputTexture = inputTexture
        self.lutTexture = lutTexture
        self.blend = blend
        self.outputTexture = outputTexture
        kernel = try Ultraviolence.ShaderLibrary(bundle: .main).applyLUT
    }

    var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            let threads = MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
            let threadsPerThreadgroup = MTLSize(width: 32, height: 32, depth: 1)
            // TODO: #52 Compute threads per threadgroup
            ComputeDispatch(threads: threads, threadsPerThreadgroup: threadsPerThreadgroup)
                .parameter("inputTexture", texture: inputTexture)
                .parameter("lutTexture", texture: lutTexture)
                .parameter("outputTexture", texture: outputTexture)
                .parameter("blend", value: blend)
        }
    }
}

struct BillboardRenderPipeline: Element {
    let texture: MTLTexture

    let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 textureCoordinate [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]]
    ) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        texture2d<float> texture [[texture(1)]]
    ) {

        constexpr sampler s;
        return texture.sample(s, in.textureCoordinate);
    }
    """

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]

    init(texture: MTLTexture) throws {
        self.texture = texture
        self.vertexShader = try VertexShader(source: source)
        self.fragmentShader = try FragmentShader(source: source)
        positions = [[-1, 1], [-1, -1], [1, 1], [1, -1]]
        textureCoordinates = [[0, 1], [0, 0], [1, 1], [1, 0]]
    }

    var body: some Element {
        get throws {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 0)
                    encoder.setVertexBytes(textureCoordinates, length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                .parameter("texture", texture: texture)
            }
        }
    }
}

@MainActor
func create3DLUT(device: MTLDevice, from lut2DTexture: MTLTexture) throws -> MTLTexture? {
    //    return createIdentityLUT3D(device: device)

    let source = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void lut2DTo3D(texture2d<float, access::read> lut2D [[texture(0)]],
                          texture3d<float, access::write> lut3D [[texture(1)]],
                          uint3 gid [[thread_position_in_grid]]) {
        const uint lutSize = 64;
        if (gid.x >= lutSize || gid.y >= lutSize || gid.z >= lutSize) return;
        uint tilesPerRow = 8;
        uint tileX = gid.z % tilesPerRow;
        uint tileY = gid.z / tilesPerRow;
        uint x = tileX * lutSize + gid.x;
        uint y = tileY * lutSize + gid.y;
        float4 color = lut2D.read(uint2(x, y));
        lut3D.write(color, gid);
    }
    """

    let size = MTLSize(width: 64, height: 64, depth: 64)
    let descriptor = MTLTextureDescriptor()
    descriptor.textureType = .type3D
    descriptor.pixelFormat = lut2DTexture.pixelFormat
    descriptor.width = size.width
    descriptor.height = size.height
    descriptor.depth = size.depth
    descriptor.usage = [.shaderRead, .shaderWrite]
    let texture3D = device.makeTexture(descriptor: descriptor)!
    let pass = try ComputePass {
        try ComputePipeline(computeKernel: .init(source: source)) {
            let threadsPerThreadgroup = MTLSize(width: 16, height: 8, depth: 8)
            // TODO: #52 Compute threads per threadgroup
            ComputeDispatch(threads: size, threadsPerThreadgroup: threadsPerThreadgroup)
                .parameter("lut2D", texture: lut2DTexture)
                .parameter("lut3D", texture: texture3D)
        }
    }
    try pass.run()
    return texture3D
}

func createIdentityLUT3D(device: MTLDevice, lutSize: Int = 64) -> MTLTexture? {
    let pixelCount = lutSize * lutSize * lutSize
    let bytesPerPixel = 4 // RGBA8 (1 byte per channel)
    var textureData = [SIMD4<UInt8>](repeating: .zero, count: pixelCount)
    for z in 0..<lutSize {
        for y in 0..<lutSize {
            for x in 0..<lutSize {
                let rgb = SIMD3<Float>(Float(x), Float(y), Float(z)) / Float(lutSize - 1)
                let pixel = SIMD3<UInt8>(rgb * 255)
                let index = (z * lutSize + y) * lutSize + x
                textureData[index] = SIMD4<UInt8>(pixel, 255)
            }
        }
    }
    let descriptor = MTLTextureDescriptor()
    descriptor.textureType = .type3D
    descriptor.pixelFormat = .rgba8Unorm
    descriptor.width = lutSize
    descriptor.height = lutSize
    descriptor.depth = lutSize
    descriptor.usage = [.shaderRead]
    guard let texture = device.makeTexture(descriptor: descriptor) else {
        return nil
    }
    let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: lutSize, height: lutSize, depth: lutSize))
    texture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: textureData, bytesPerRow: lutSize * bytesPerPixel, bytesPerImage: lutSize * lutSize * bytesPerPixel)
    return texture
}
