import simd

public struct Packed3<Scalar> where Scalar: SIMDScalar {
    public var x: Scalar
    public var y: Scalar
    public var z: Scalar

    public init(x: Scalar, y: Scalar, z: Scalar) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public extension Packed3 {
    subscript(i: Int) -> Scalar {
        get {
            switch i {
            case 0:
                return x
            case 1:
                return y
            case 2:
                return z
            default:
                fatalError("Index out of bounds.")
            }
        }
        set {
            switch i {
            case 0:
                x = newValue
            case 1:
                y = newValue
            case 2:
                z = newValue
            default:
                fatalError("Index out of bounds.")
            }
        }
    }
}

extension Packed3: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Scalar...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}

extension Packed3: Sendable where Scalar: Sendable {
}

extension Packed3: Equatable where Scalar: Equatable {
}

public extension Packed3 where Scalar: Numeric {
    // TODO: #137 Flesh this out.
    static func *(lhs: Self, rhs: Scalar) -> Self {
        Self(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
}

public extension Packed3 {
    init(_ other: Packed3<Scalar>) {
        self = other
    }
    init(_ other: SIMD3<Scalar>) {
        self.init(x: other.x, y: other.y, z: other.z)
    }
}

#if os(iOS) || (os(macOS) && !arch(x86_64))
public extension Packed3 where Scalar == Float {
    init(_ other: Packed3<Float16>) {
        self.init(x: Float(other.x), y: Float(other.y), z: Float(other.z))
    }
}

public extension Packed3 where Scalar == Float16 {
    init(_ other: Packed3<Float>) {
        self.init(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z))
    }
    init(_ other: SIMD3<Float>) {
        self.init(x: Float16(other.x), y: Float16(other.y), z: Float16(other.z))
    }
}
#endif // os(iOS) || (os(macOS) && !arch(x86_64))

public extension SIMD3 {
    init(_ packed: Packed3<Scalar>) {
        self.init(packed.x, packed.y, packed.z)
    }
}
