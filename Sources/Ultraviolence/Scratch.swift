import Metal
import simd
import MetalKit
import SwiftUI

// TODO: Placeholder.
public struct Texture {
    public init() {
    }

    public init(size: SIMD2<Float>) {
    }
}

// TODO: Name conflict with SwiftUI.
// TODO: Placeholder.
public struct ForEach_ <Data, Content>: RenderPass where Content: RenderPass {
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

@propertyWrapper
// TODO: Placeholder.
public struct State_ <Wrapped> {

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

// TODO: Placeholder.
public struct Chain <Content: RenderPass>: RenderPass where Content: RenderPass {
    var content: Content

    public init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some RenderPass {
        content
    }
}

