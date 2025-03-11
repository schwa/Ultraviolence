import simd

public struct GenericSplat: Equatable {
    public var position: SIMD3<Float>
    public var scale: SIMD3<Float>
    public var color: SIMD4<Float>
    public var rotation: simd_quatf

    public init(position: SIMD3<Float>, scale: SIMD3<Float>, color: SIMD4<Float>, rotation: simd_quatf) {
        self.position = position
        self.scale = scale
        self.color = color
        self.rotation = rotation
    }
}

extension GenericSplat: Decodable {
    enum CodingKeys: String, CodingKey {
        case position
        case scale
        case color
        case rotation
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decode(SIMD3<Float>.self, forKey: .position)
        scale = try container.decode(SIMD3<Float>.self, forKey: .scale)
        color = try container.decode(SIMD4<Float>.self, forKey: .color)
        let rotationVector = try container.decode(SIMD4<Float>.self, forKey: .rotation)
        rotation = simd_quatf(angle: rotationVector.w, axis: SIMD3<Float>(rotationVector.x, rotationVector.y, rotationVector.z))
    }
}

public extension Antimatter15Splat {
    init(_ other: GenericSplat) {
        let position = Packed3<Float>(other.position)
        let scale = Packed3<Float>(other.scale)
        let color = SIMD4<UInt8>(other.color.clamped(to: 0...1) * 255)
        let rotation_vector = other.rotation.vectorRealFirst
        let rotation = ((rotation_vector / rotation_vector.length) * 128 + 128).clamped(to: 0...255)
        self = Antimatter15Splat(position: position, scale: scale, color: color, rotation: SIMD4<UInt8>(rotation))
    }
}

extension simd_float4 {
    var length: Scalar {
        simd_length(self)
    }
}

extension SIMD4 where Scalar == Float {
    func clamped(to range: ClosedRange<Scalar>) -> Self {
        Self(map { $0.clamped(to: range) })
    }
}

extension simd_quatf {
    var vectorRealFirst: simd_float4 {
        [vector.w, vector.x, vector.y, vector.z]
    }
}
