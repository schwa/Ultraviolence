import CoreGraphics
import Foundation
import Testing
@testable import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

@MainActor
struct UltraviolenceExampleTests {
    @Test(arguments: [
        MemcpyComputeDemo.self,
        RedTriangleInline.self,
        TraditionalRedTriangle.self,
        CheckerboardKernel.self,
        FlatShaderExample.self,
        MixedExample.self
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
