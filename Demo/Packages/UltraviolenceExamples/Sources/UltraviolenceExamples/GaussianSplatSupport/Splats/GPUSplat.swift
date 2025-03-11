import GaussianSplatShaders
import simd

// `struct GPUSplat` defined in GaussianSplatShaders package.
// struct GPUSplat {
//     simd_float3 position; // 12
//     // padding            // 4
//     simd_half2 u1;        // 4
//     simd_half2 u2;        // 4
//     simd_half2 u3;        // 4
//     simd_uchar4 color;    // 4
// };

extension GPUSplat: @unchecked @retroactive Sendable {
}

extension GPUSplat: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.position == rhs.position
            && lhs.color == rhs.color
            && lhs.u1 == rhs.u1
            && lhs.u2 == rhs.u2
            && lhs.u3 == rhs.u3
    }
}

extension GPUSplat: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "GPUSplat(position: [\(position.x), \(position.y), \(position.z)], u1: [\(u1.x), \(u1.y)], u2: [\(u2.x), \(u2.y)], u3: [\(u3.x), \(u3.y)], color: [\(color.x), \(color.y), \(color.z), \(color.w)])"
    }
}

extension GPUSplat: SplatProtocol {
    public var floatPosition: SIMD3<Float> {
        SIMD3<Float>(position)
    }
}
