import MetalKit
import simd

// TOOD: Placeholder.
public protocol Geometry {
    func mesh() throws -> Mesh
}

// TOOD: Placeholder.
public enum Mesh {
    case simple([SIMD3<Float>])
    case mtkMesh(MTKMesh)
}

// MARK: -

public struct Quad2D {
    public var origin: SIMD2<Float> = .zero
    public var size: SIMD2<Float> = .one

    public init(origin: SIMD2<Float>, size: SIMD2<Float>) {
        self.origin = origin
        self.size = size
    }
}

extension Quad2D: Geometry {
    public func mesh() throws -> Mesh {
        .simple(vertices(for: .triangle))
    }

    func vertices(for primitive: MTLPrimitiveType) -> [SIMD3<Float>] {
        switch primitive {
        case .triangle:
            return [
                // Two triangles (six vertices) forming a quad.
                [origin.x, origin.y, 0],
                [origin.x + size.x, origin.y, 0],
                [origin.x, origin.y + size.y, 0],
                [origin.x + size.x, origin.y, 0],
                [origin.x + size.x, origin.y + size.y, 0],
                [origin.x, origin.y + size.y, 0],
            ]
        default:
            fatalError()
        }
    }
}
