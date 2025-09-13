import Foundation
import Metal
import simd
import Ultraviolence
import UltraviolenceSupport

struct CubeReader {
    // NOTE: Use https://github.com/fastfloat/fast_float
    // NOTE: This assumes the .cube file has a single 3D lut in it. See here for more: https://resolve.cafe/developers/luts/
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
            if line.hasPrefix("#") {
                continue
            }
            if title == nil, let match = try titleRegex.firstMatch(in: String(line)) {
                title = match.output.1
            }
            else if is3D == nil, let match = try lut3DSizeRegex.firstMatch(in: String(line)) {
                is3D = true
                count = try Int(match.output.1).orThrow(.generic("Failed to parse LUT_3D_SIZE value"))
            }
            else {
                let components = line.split(separator: " ")
                guard components.count == 3 else {
                    throw UltraviolenceError.validationError("Invalid LUT entry: expected 3 components, got \(components.count)")
                }
                let r = try Float(components[0]).orThrow(.generic("Failed to parse red component"))
                let g = try Float(components[1]).orThrow(.generic("Failed to parse green component"))
                let b = try Float(components[2]).orThrow(.generic("Failed to parse blue component"))
                values.append(SIMD3<Float>(r, g, b))
            }
        }

        guard let is3D, is3D == true, let count else {
            throw UltraviolenceError.configurationError("Missing or invalid LUT_3D_SIZE declaration in .cube file")
        }

        guard values.count == count * count * count else {
            throw UltraviolenceError.validationError("LUT data size mismatch: expected \(count * count * count) entries, got \(values.count)")
        }

        self.title = String(title ?? "")
        self.count = count
        self.values = values
    }
}

extension CubeReader {
    @MainActor
    func toTexture() throws -> MTLTexture {
        let device = _MTLCreateSystemDefaultDevice()
        let pixels = values.map { SIMD4<Float>($0, 1) }
        let outputDescriptor = MTLTextureDescriptor()
        outputDescriptor.textureType = .type3D
        outputDescriptor.pixelFormat = .rgba32Float
        outputDescriptor.width = count
        outputDescriptor.height = count
        outputDescriptor.depth = count
        outputDescriptor.usage = [.shaderRead, .shaderWrite]
        let outputTexture = try device._makeTexture(descriptor: outputDescriptor)
        outputTexture.label = "Output Texture (\(title))"
        pixels.withUnsafeBytes { buffer in
            let region = MTLRegionMake3D(0, 0, 0, outputTexture.width, outputTexture.height, outputTexture.depth)
            let bytesPerRow = outputTexture.width * MemoryLayout<SIMD4<Float>>.size
            let bytesPerImage = bytesPerRow * outputTexture.height
            outputTexture.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: buffer.baseAddress!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        }
        return outputTexture
    }
}
