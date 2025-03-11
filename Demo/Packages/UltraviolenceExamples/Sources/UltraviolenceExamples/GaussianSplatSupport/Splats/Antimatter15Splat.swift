import GaussianSplatShaders
import UniformTypeIdentifiers

extension UTType {
    // An buffer of Antimatter15Splat in little endian format.
    static let antimatter15Splat = UTType(filenameExtension: "splat")!
}

/// Defined as the .splat file format by Antimatter15 - http://antimatter15.com/splat/ and https://github.com/antimatter15/splat - it doesn't include spherical harmonics and is 32 bytes per splat.
public struct Antimatter15Splat: Equatable, Sendable {
    public var position: Packed3<Float>
    public var scale: Packed3<Float>
    public var color: SIMD4<UInt8>
    public var rotation: SIMD4<UInt8>

    public init(position: Packed3<Float>, scale: Packed3<Float>, color: SIMD4<UInt8>, rotation: SIMD4<UInt8>) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}

public extension GPUSplat {
    init(_ splat: Antimatter15Splat) {
        // Extract position
        let position = splat.position

        // Copy color components directly
        let color = splat.color

        // Extract scale
        let scale = splat.scale

        // Map rotation components from UInt8 (0..255) to Float in [-1, 1]
        let rot: [Float] = splat.rotation.map { (Float($0) - 128.0) / 128.0 }.scalars

        // Calculate individual matrix elements (flattened)
        let m = [
            1.0 - 2.0 * (rot[2] * rot[2] + rot[3] * rot[3]),
            2.0 * (rot[1] * rot[2] + rot[0] * rot[3]),
            2.0 * (rot[1] * rot[3] - rot[0] * rot[2]),

            2.0 * (rot[1] * rot[2] - rot[0] * rot[3]),
            1.0 - 2.0 * (rot[1] * rot[1] + rot[3] * rot[3]),
            2.0 * (rot[2] * rot[3] + rot[0] * rot[1]),

            2.0 * (rot[1] * rot[3] + rot[0] * rot[2]),
            2.0 * (rot[2] * rot[3] - rot[0] * rot[1]),
            1.0 - 2.0 * (rot[1] * rot[1] + rot[2] * rot[2])
        ].enumerated().map { $0.element * scale[$0.offset / 3] }

        // Compute sigma values
        var sigma = [
            m[0] * m[0] + m[3] * m[3] + m[6] * m[6],
            m[0] * m[1] + m[3] * m[4] + m[6] * m[7],
            m[0] * m[2] + m[3] * m[5] + m[6] * m[8],
            m[1] * m[1] + m[4] * m[4] + m[7] * m[7],
            m[1] * m[2] + m[4] * m[5] + m[7] * m[8],
            m[2] * m[2] + m[5] * m[5] + m[8] * m[8]
        ]

        sigma = sigma.map { $0 * 4 }

        // Convert sigma values into simd_half2 pairs
        let u1 = simd_half2(Float16(sigma[0]), Float16(sigma[1]))
        let u2 = simd_half2(Float16(sigma[2]), Float16(sigma[3]))
        let u3 = simd_half2(Float16(sigma[4]), Float16(sigma[5]))

        // Construct and return the GPUSplat
        self = GPUSplat(
            position: SIMD3<Float>(position),
            u1: u1,
            u2: u2,
            u3: u3,
            color: color
        )
    }
}
