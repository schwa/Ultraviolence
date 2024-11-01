import Metal
import simd

public protocol Geometry {
    func vertices(for primitive: MTLPrimitiveType) -> [SIMD3<Float>]
}

public struct Quad2D {
    public var origin: SIMD2<Float> = .zero
    public var size: SIMD2<Float> = .one

    public init(origin: SIMD2<Float>, size: SIMD2<Float>) {
        self.origin = origin
        self.size = size
    }
}

extension Quad2D: Geometry {
    public func vertices(for primitive: MTLPrimitiveType) -> [SIMD3<Float>] {
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

// MARK: -

public struct Texture {
    public init() {
    }

    public init(size: SIMD2<Float>) {
    }
}

// TODO: Name conflict with SwiftUI.
public struct ForEach <Data, Content>: RenderPass where Content: RenderPass {
    var data: Data
    var content: (Data) throws -> Content

    public init(_ data: Data, @RenderPassBuilder content: @escaping (Data) throws -> Content) {
        self.data = data
        self.content = content
    }

    public var body: some RenderPass {
        fatalError()
    }
}

// TODO: Name conflict with SwiftUI.
@propertyWrapper
public struct State <Wrapped> {

    public init() {
    }

    public var wrappedValue: Wrapped {
        get {
            fatalError()
        }
        nonmutating set {
            fatalError()
        }
    }
}

public struct Chain <Content: RenderPass>: RenderPass where Content: RenderPass {
    var content: Content

    public init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some RenderPass {
        content
    }
}

public extension RenderPass {
    func uniform(_ name: String, _ value: Any) -> some RenderPass {
        return self
    }

    func renderTarget(_ texture: Texture) -> some RenderPass {
        return self
    }
}

