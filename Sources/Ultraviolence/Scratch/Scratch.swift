import Metal
import MetalKit
import simd

// TODO: Placeholder.
@available(*, deprecated, message: "Dont use (yet?)")
public struct Texture {
    public init() {
        fatalError("Not implemented")
    }

    public init(size: SIMD2<Float>) {
        fatalError("Not implemented")
    }
}

// TODO: Name conflict with SwiftUI.
// TODO: Placeholder.
@available(*, deprecated, message: "Dont use (yet?)")
public struct ForEach_ <Data, Content>: RenderPass where Content: RenderPass {
    var data: Data
    var content: (Data) throws -> Content

    public init(_ data: Data, @RenderPassBuilder content: @escaping (Data) throws -> Content) {
        self.data = data
        self.content = content
    }

    public var body: some RenderPass {
        fatalError("Not implemented")
    }
}

@available(*, deprecated, message: "Dont use (yet?)")
@propertyWrapper
// TODO: Placeholder.
public struct State_ <Wrapped> {
    public init() {
        fatalError("Not implemented")
    }

    public var wrappedValue: Wrapped {
        get {
            fatalError("Not implemented")
        }
        nonmutating set {
            fatalError("Not implemented")
        }
    }
}
