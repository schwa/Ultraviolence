import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

public extension Draw {
    init(mtkMesh: MTKMesh) {
        self.init { encoder in
            encoder.setVertexBuffers(of: mtkMesh)
            encoder.draw(mtkMesh)
        }
    }
}

public extension MTLDevice {
    @MainActor
    func makeTexture(content: some View) throws -> MTLTexture {
        var cgImage: CGImage?
        let renderer = ImageRenderer(content: content)
        renderer.render { size, callback in
            guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return
            }
            callback(context)
            cgImage = context.makeImage()
        }
        let textureLoader = MTKTextureLoader(device: self)
        guard let cgImage else {
            throw UltraviolenceError.generic("Failed to create image.")
        }
        return try textureLoader.newTexture(cgImage: cgImage, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .SRGB: false
        ])
    }
}

public extension MTLDevice {
    @MainActor
    func makeTextureCubeFromCrossTexture(texture: MTLTexture) throws -> MTLTexture {
        // Convert a skybox texture stored as a "cross" shape in a 2d texture into a texture cube:
        //     [5]
        // [1] [4] [0] [5]
        //     [2]
        let size = SIMD2<Int>(texture.width / 4, texture.height / 3)
        let cellWidth = texture.width / 4
        let cellHeight = texture.height / 3
        let cubeMapDescriptor = MTLTextureDescriptor()
        cubeMapDescriptor.textureType = .typeCube
        cubeMapDescriptor.pixelFormat = texture.pixelFormat
        cubeMapDescriptor.width = size.x
        cubeMapDescriptor.height = size.y
        guard let cubeMap = makeTexture(descriptor: cubeMapDescriptor) else {
            throw UltraviolenceError.generic("Failed to create texture cube.")
        }
        let blit = try BlitPass {
            Blit { encoder in
                let origins: [SIMD2<Int>] = [
                    [2, 1], [0, 1], [1, 0], [1, 2], [1, 1], [3, 1]
                ]
                for (slice, origin) in origins.enumerated() {
                    let origin = SIMD2<Int>(origin.x * cellWidth, origin.y * cellHeight)
                    encoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: .init(x: origin.x, y: origin.y, z: 0), sourceSize: .init(width: size.x, height: size.y, depth: 1), to: cubeMap, destinationSlice: slice, destinationLevel: 0, destinationOrigin: .init(x: 0, y: 0, z: 0))
                }
            }
        }
        try blit.run()
        return cubeMap
    }
}
