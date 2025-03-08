import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence

extension simd_quatf {
    static var identity: simd_quatf {
        simd_quatf(angle: 0, axis: [0, 1, 0]) // No rotation
    }
}

struct Packed3<Scalar> where Scalar: SIMDScalar {
    var x: Scalar
    var y: Scalar
    var z: Scalar
}

extension Packed3: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Scalar...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}

extension Packed3 where Scalar: Numeric {
    static func *(lhs: Self, rhs: Scalar) -> Self {
        Self(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
}

extension Draw {
    init(mtkMesh: MTKMesh) {
        self.init { encoder in
            encoder.setVertexBuffers(of: mtkMesh)
            encoder.draw(mtkMesh)
        }
    }
}

extension MTLDevice {
    func makeTexture(name: String, bundle: Bundle? = nil) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self)
        return try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: bundle)
    }
}

extension SIMD4<Float> {
    init(color: Color) {
        let resolved = color.resolve(in: .init())
        self = [
            Float(resolved.linearRed),
            Float(resolved.linearGreen),
            Float(resolved.linearBlue),
            Float(1.0) // TODO:
        ]
    }
}

internal struct BoundingBox {
    var min: SIMD3<Float>
    var max: SIMD3<Float>
}

extension MTLDevice {
    @MainActor
    func makeTexture(content: some View) throws -> MTLTexture {
        var cgImage: CGImage?
        let renderer = ImageRenderer(content: content)
        renderer.render { size, callback in
            let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

            callback(context)

            cgImage = context.makeImage()
        }

        let textureLoader = MTKTextureLoader(device: self)
        return try textureLoader.newTexture(cgImage: cgImage!, options: [
            .textureUsage: MTLTextureUsage([.shaderRead, .shaderWrite]).rawValue,
            .SRGB: false
        ])
    }

    @MainActor
    func makeTextureCubeFromCrossTexture(texture: MTLTexture) -> MTLTexture {
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
        let cubeMap = makeTexture(descriptor: cubeMapDescriptor)!
        let blit = try! BlitPass {
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
        try! blit.run()
        return cubeMap
    }
}
