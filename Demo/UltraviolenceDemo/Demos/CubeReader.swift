import Foundation
import simd
import UltraviolenceSupport
import Ultraviolence
import Metal

struct CubeReader {

    // TODO: Use https://github.com/fastfloat/fast_float

    var title: String
    var count: Int
    var values: [SIMD3<Float>] = []

    init(url: URL) throws {
        let string = try String(contentsOf: url, encoding: .utf8)
        let lines = string.split(separator: "\n")
        var title: Substring?
        var is3D: Bool?
        var count: Int?
        var values: [SIMD3<Float>] = []

        let titleRegex = #/^TITLE\s+"(.+)"$/#
        let lut3DSizeRegex = #/^LUT_3D_SIZE\s+(\d+)$/#

        for line in lines {
            let line = line.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                continue
            }
            else if line.hasPrefix("#") {
                continue
            }
            else if title == nil, let match = try titleRegex.firstMatch(in: String(line)) {
                title = match.output.1
            }
            else if is3D == nil, let match = try lut3DSizeRegex.firstMatch(in: String(line)) {
                is3D = true
                count = try Int(match.output.1).orThrow(.undefined)
            }
            else {
                let components = line.split(separator: " ")
                guard components.count == 3 else {
                    throw UltraviolenceError.undefined
                }
                let r = try Float(components[0]).orThrow(.undefined)
                let g = try Float(components[1]).orThrow(.undefined)
                let b = try Float(components[2]).orThrow(.undefined)
                values.append(SIMD3<Float>(r, g, b))
            }
        }

        guard let is3D, is3D == true, let count = count else {
            throw UltraviolenceError.undefined
        }

        guard values.count == count * count * count else {
            throw UltraviolenceError.undefined
        }

        self.title = String(title ?? "")
        self.count = count
        self.values = values
    }
}

extension CubeReader {

    @MainActor
    func toTexture() throws -> MTLTexture {
        let device = MTLCreateSystemDefaultDevice()!

        let pixels = values.map { SIMD4<Float>($0, 1) }
//        let inputBuffer = pixels.withUnsafeBytes { buffer in
//            device.makeBuffer(bytes: buffer.baseAddress!, length: pixels.count * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)!
//        }
//        inputBuffer.label = "Input Buffer"

        let outputDescriptor = MTLTextureDescriptor()
        outputDescriptor.textureType = .type3D
        outputDescriptor.pixelFormat = .rgba32Float
        outputDescriptor.width = count
        outputDescriptor.height = count
        outputDescriptor.depth = count
        outputDescriptor.usage = [.shaderRead, .shaderWrite]

        let outputTexture = try device._makeTexture(descriptor: outputDescriptor)
        outputTexture.label = "Output Texture"

        pixels.withUnsafeBytes { buffer in
            let region = MTLRegionMake3D(0, 0, 0, outputTexture.width, outputTexture.height, outputTexture.depth)
            let bytesPerRow = outputTexture.width * MemoryLayout<SIMD4<Float>>.size
            let bytesPerImage = bytesPerRow * outputTexture.height

            outputTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: buffer.baseAddress!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        }


//        let source = """
//        #include <metal_stdlib>
//        using namespace metal;
//
//        kernel void convert1DTo3D(
//            uint3 gid [[thread_position_in_grid]],
//            constant float4 *inputBuffer [[buffer(0)]],
//            texture3d<float, access::write> outputTexture [[texture(0)]]
//        ) {
//            const uint width = outputTexture.get_width();
//            const uint height = outputTexture.get_height();
//            const uint depth = outputTexture.get_depth();
//
//            //outputTexture.write(float4(float3(gid) / float3(width, height, depth), 1.0), gid);
//            uint index = gid.x + width * (gid.y + height * gid.z);
//            // Ensure the index is within bounds
//            //            if (index < width * height * depth) {
//            float4 value = inputBuffer[index];
//            outputTexture.write(value, gid);
//        }
//        """
//
//        try MTLCaptureManager.shared().with {
//            let pass = try ComputePass {
//                try ComputePipeline(computeKernel: .init(source: source)) {
//                    let threads = MTLSize(width: count, height: count, depth: count)
//                    let threadsPerThreadgroup = MTLSize(width: 16, height: 8, depth: 8)
//                    // TODO: #52 Compute threads per threadgroup
//                    ComputeDispatch(threads: threads, threadsPerThreadgroup: threadsPerThreadgroup)
//                        .parameter("inputBuffer", buffer: inputBuffer)
//                        .parameter("outputTexture", texture: outputTexture)
//                }
//            }
//            try pass.run()
//        }
        return outputTexture
    }
}

