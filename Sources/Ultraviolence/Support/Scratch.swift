// struct ModifiedRenderPass<Content, Modifier>: RenderPass where Content: RenderPass, Modifier: RenderPassModifier, Modifier.Content == Content {
//    var content: Content
//    var modifier: Modifier
//
//    var body: some RenderPass {
//        modifier.body(content: content)
//    }
// }
//
// @MainActor public protocol RenderPassModifier {
//    associatedtype Body : RenderPass
//    @RenderPassBuilder @MainActor func body(content: Self.Content) -> Self.Body
//    associatedtype Content
// }
//
