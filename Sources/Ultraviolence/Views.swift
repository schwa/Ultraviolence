import SwiftUI

public struct RenderView <Content>: View where Content: RenderPass {
    @RenderPassBuilder
    var content: Content

    public init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        EmptyView()
    }
}

public extension View {
    func onDrawableSizeChange(initial: Bool = false, _ body: (SIMD2<Float>) -> Void) -> some View {
        return self
    }
}

