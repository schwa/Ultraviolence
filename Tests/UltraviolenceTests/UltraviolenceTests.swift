import Testing
import CoreGraphics
@testable import Ultraviolence
import Examples

struct RenderingTests {
    @Test
    func simpleRender() async throws {
        let size = CGSize(width: 1600, height: 1200)
        let renderPass = TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: .init(translation: [0, 0, 0]), view: .init(translation: [0, 0, 0]), cameraPosition: [0, 0, 0])
        let renderer = Renderer(size: size, content: renderPass)
        let image = try renderer.render().cgImage
        #expect(image != nil)
    }
}
