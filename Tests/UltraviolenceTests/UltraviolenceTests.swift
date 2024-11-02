import Testing
import CoreGraphics
@testable import Ultraviolence
import Examples

struct RenderingTests {
    @Test
    func simpleRender() async throws {
        let renderer = Renderer(TeapotRenderPass(color: [1, 0, 0, 1], size: CGSize(width: 1600, height: 1200), model: .init(translation: [0, 0, 0]), view: .init(translation: [0, 0, 0]), cameraPosition: [0, 0, 0]))
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage
        #expect(image != nil)
    }
}
