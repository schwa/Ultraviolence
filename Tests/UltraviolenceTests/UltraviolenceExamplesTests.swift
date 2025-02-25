import CoreGraphics
import Testing
@testable import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

@MainActor
struct UltraviolenceExampleTests {
    @Test
    func testMixedExample() throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let element = MixedExample(modelMatrix: .identity, color: [1, 0, 0, 1], lightDirection: [1, 1, 1])
        //        let element = MixedExample(modelMatrix: .identity, color: [1, 1, 0, 1], lightDirection: [1, 1, 1])
        let image = try offscreenRenderer.render(element, capture: true).cgImage
        let goldenImage = goldenImage(named: "MixedExample")
        #expect(try imageCompare(image, goldenImage) == true)
    }
}
