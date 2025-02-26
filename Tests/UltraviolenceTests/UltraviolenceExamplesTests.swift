import CoreGraphics
import Foundation
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
        let element = MixedExample(modelMatrix: .identity, color: [1, 0, 0], lightDirection: [1, 1, 1])
        //        let element = MixedExample(modelMatrix: .identity, color: [1, 1, 0, 1], lightDirection: [1, 1, 1])
        let image = try offscreenRenderer.render(element, capture: true).cgImage
        let goldenImage = goldenImage(named: "MixedExample")
        #expect(try imageCompare(image, goldenImage) == true)
    }

    @Test(arguments: [
        CheckerboardKernel.self,
        FlatShaderExample.self,
        MixedExample.self,
    ] as [any Example.Type])
    func testExample(_ example: Example.Type) throws {
        let result = try example.runExample()
        switch result {
        case .texture(let texture):
            let url = URL(fileURLWithPath: "/tmp/\(example).png")
            try texture.write(to: url)
            let image = try texture.toCGImage()
            let goldenImage = goldenImage(named: "\(example)")
            #expect(try imageCompare(image, goldenImage) == true)
        default:
            break
        }
    }
}
