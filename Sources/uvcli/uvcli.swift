import Foundation
import UltraviolenceExamples

@main
struct UVCLI {
    @MainActor
    static func main() throws {
        let name = ProcessInfo.processInfo.environment["DEMO"]
        var demo: Demo.Type?
        demo = demos.first { demo in
            demo.name == name
        }
        if demo == nil {
            print("Available demos:")
            for (index, demo) in demos.enumerated() {
                print("  \(index + 1): \(demo.name)")
            }
            print("Demo #? ", terminator: "")
            let name = readLine()!
            let index = Int(name)! - 1
            demo = demos[index]
        }
        guard let demo else {
            print("No demo found.")
            return
        }
        try demo.main()
    }
}

protocol Demo {
    @MainActor
    static func main() throws

    static var name: String { get }
}

extension Demo {
    static var name: String {
        "\(self)"
    }
}

enum AllDemos: Demo {
    static let name: String = "All"

    static func main() throws {
        for demo in demos[1...] {
            print("Running \(demo.name)...")
            try demo.main()
        }
    }
}

extension HelloWorldComputeDemo: Demo {
}

extension RedTriangle: Demo {
}

extension TraditionalRedTriangle: Demo {
}

extension TeapotDemo: Demo {
}

extension MemcpyComputeDemo: Demo {
}

let demos: [Demo.Type] = [
    AllDemos.self,
    HelloWorldComputeDemo.self,
    RedTriangle.self,
    TraditionalRedTriangle.self,
    TeapotDemo.self,
    MemcpyComputeDemo.self
]
