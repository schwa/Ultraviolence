import CoreGraphics
import Testing
@testable import Ultraviolence
import UltraviolenceExamples

public struct RenderingTests {
    @Test
    func simpleRender() async throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let renderPass = TeapotRenderPass(color: [1, 0, 0, 1], size: size, model: .init(translation: [0, 0, 0]), view: .init(translation: [0, 0, 0]), cameraPosition: [0, 0, 0])
        let renderer = try OffscreenRenderer(size: size, content: Render { renderPass })
        let image = try renderer.render().cgImage
        #expect(image != nil)
    }
}
