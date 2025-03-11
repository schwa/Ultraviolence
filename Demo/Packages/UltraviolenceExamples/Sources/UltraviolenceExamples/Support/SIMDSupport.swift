import simd

public extension simd_float4x4 {
    init(scale: SIMD3<Float>) {
        self.init([
            [scale.x, 0, 0, 0],
            [0, scale.y, 0, 0],
            [0, 0, scale.z, 0],
            [0, 0, 0, 1]
        ])
    }

    init(translation: SIMD3<Float>) {
        self.init([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [translation.x, translation.y, translation.z, 1]
        ])
    }

    init(xRotation: Angle) {
        let radians = Float(xRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [1, 0, 0, 0],
            [0, c, -s, 0],
            [0, s, c, 0],
            [0, 0, 0, 1]
        ])
    }

    init(yRotation: Angle) {
        let radians = Float(yRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, 0, s, 0],
            [0, 1, 0, 0],
            [-s, 0, c, 0],
            [0, 0, 0, 1]
        ])
    }

    init(zRotation: Angle) {
        let radians = Float(zRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, -s, 0, 0],
            [s, c, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ])
    }

    var translation: SIMD3<Float> {
        get {
            self[3].xyz
        }
        set {
            self[3].xyz = newValue
        }
    }

    static let identity = simd_float4x4(diagonal: [1, 1, 1, 1])
}

extension SIMD3 {
    var xy: SIMD2<Scalar> {
        get {
            .init(x, y)
        }
        set {
            x = newValue.x
            y = newValue.y
        }
    }
}

public extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        get {
            .init(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}

public extension simd_float4x4 {
    var upperLeft: simd_float3x3 {
        simd_float3x3(columns: (
            simd_float3(columns.0.xyz),
            simd_float3(columns.1.xyz),
            simd_float3(columns.2.xyz)
        ))
    }
}

public extension SIMD3 {
    func map<T>(_ transform: (Scalar) -> T) -> SIMD3<T> where T: SIMDScalar {
        .init(transform(x), transform(y), transform(z))
    }
}

public extension SIMD4 {
    func map<T>(_ transform: (Scalar) -> T) -> SIMD4<T> where T: SIMDScalar {
        .init(transform(x), transform(y), transform(z), transform(w))
    }
}

public extension SIMD4 {
    var scalars: [Scalar] {
        [x, y, z, w]
    }
}
