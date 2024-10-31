import simd

public protocol Geometry {
}

public struct Texture {
    public init() {
    }

    public init(size: SIMD2<Float>) {
    }
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
}

public struct ForEach_ <Data, Content>: RenderPass where Content: RenderPass {
    var data: Data
    var content: (Data) -> Content

    public init(_ data: Data, @RenderPassBuilder content: @escaping (Data) -> Content) {
        self.data = data
        self.content = content
    }

    public var body: some RenderPass {
        fatalError()
    }
}

@propertyWrapper
public struct RenderState <Wrapped> {

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

public struct List_ <Content: RenderPass>: RenderPass where Content: RenderPass {
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

