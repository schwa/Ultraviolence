import Foundation
import UltraviolenceExamples
import os

@main
struct UVCLI {
    @MainActor
    static func main() throws {

        let logger = Logger()

        let examples: [Example.Type] = [
            MemcpyComputeDemo.self,
            RedTriangle.self,
            TraditionalRedTriangle.self,
            CheckerboardKernel.self,
            FlatShaderExample.self,
            MixedExample.self,
        ]

        for example in examples {
            do {
                logger.log("Running: \(example)")
                let result = try example.runExample()
                switch result {
                case .texture(let texture):
                    let url = URL(fileURLWithPath: "/tmp/\(example).png")
                    try texture.write(to: url)
                default:
                    break
                }
            }
            catch {
                logger.error("Error: \(error)")
            }
        }
    }
}

