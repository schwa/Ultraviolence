import Ultraviolence
import Metal
import MetalKit
import SwiftUI

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
