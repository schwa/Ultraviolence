import simd
import SwiftUI

@resultBuilder
struct RenderPassBuilder {
    static func buildBlock() -> EmptyPass {
        fatalError()
    }

    static func buildBlock<Content>(_ content: Content) -> Content where Content : RenderPass {
        content
    }

    static func buildBlock<each Content>(_ content: repeat each Content) -> TuplePass<(repeat each Content)> where repeat each Content: RenderPass {
        fatalError()
    }
}

struct TuplePass <T>: RenderPass {
    var body: some RenderPass {
        fatalError()
    }
}

protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get }
}

struct Geometry {
}

struct Texture {
    init() {

    }

    init(size: SIMD2<Float>) {
    }
}

struct EmptyPass: RenderPass {
    var body: some RenderPass {
        fatalError()
    }
}

@propertyWrapper
struct RenderState <Wrapped> {
    public var wrappedValue: Wrapped {
        get {
            fatalError()
        }
        nonmutating set {
            fatalError()
        }
    }
}

struct List_ <Content: RenderPass>: RenderPass where Content: RenderPass {
    var content: Content

    init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some RenderPass {
        content
    }
}


struct Draw <Content: RenderPass>: RenderPass where Content: RenderPass {
    var geometry: Geometry
    var content: Content

    init(_ geometry: Geometry, @RenderPassBuilder content: () -> Content) {
        self.geometry = geometry
        self.content = content()
    }

    var body: some RenderPass {
        content
    }
}

extension RenderPass {
    func uniform(_ name: String, _ value: Any) -> some RenderPass {
        return self
    }

    func renderTarget(_ texture: Texture) -> some RenderPass {
        return self
    }
}

extension Never: RenderPass {
}

struct VertexShader: RenderPass {
    var name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some RenderPass {
        fatalError()
    }
}

struct FragmentShader: RenderPass {
    var name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some RenderPass {
        fatalError()
    }
}

struct MetalFXUpscaler: RenderPass {
    init(input: Texture) {
    }

    var body: some RenderPass {
        fatalError()
    }
}

struct Blit: RenderPass {
    init(input: Texture) {
    }

    var body: some RenderPass {
        fatalError()
    }
}

struct RenderView <Content>: View where Content: RenderPass {
    @RenderPassBuilder
    var content: Content

    var body: some View {
        EmptyView()
    }
}

extension View {
    func onDrawableSizeChange(initial: Bool = false, _ body: (SIMD2<Float>) -> Void) -> some View {
        return self
    }
}

struct ForEach_ <Data, Content>: RenderPass where Content: RenderPass {

    var data: Data
    var content: (Data) -> Content

    init(_ data: Data, @RenderPassBuilder content: @escaping (Data) -> Content) {
        self.data = data
        self.content = content
    }

    var body: some RenderPass {
        fatalError()
    }
}
