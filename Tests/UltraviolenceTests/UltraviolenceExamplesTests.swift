import CoreGraphics
import Foundation
import Testing
@testable import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

@MainActor
struct UltraviolenceExampleTests {
    @Test(.disabled("Disabled - failing on CI"), .bug("https://github.com/schwa/Ultraviolence/issues/38", "Caught error: Error Domain=MTLLibraryErrorDomain Code=6 \"no default library was found\" UserInfo={NSLocalizedDescription=no default library was found}"))
    func testMixedExample() throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let element = MixedExample(modelMatrix: .identity, color: [1, 0, 0], lightDirection: [1, 1, 1])
        //        let element = MixedExample(modelMatrix: .identity, color: [1, 1, 0, 1], lightDirection: [1, 1, 1])
        let image = try offscreenRenderer.render(element, capture: true).cgImage
        let goldenImage = goldenImage(named: "MixedExample")
        #expect(try imageCompare(image, goldenImage) == true)
    }

    @Test
    func testAllExamples() throws {
        let examples: [Example.Type] = [
            CheckerboardKernel.self,
            FlatShaderExample.self,
            MixedExample.self
        ]
        for example in examples {
            let result = try example.runExample()
            switch result {
            case .texture(let texture):
                let url = URL(fileURLWithPath: "/tmp/\(example).png")
                try texture.write(to: url)
            default:
                break
            }
        }
    }
}
