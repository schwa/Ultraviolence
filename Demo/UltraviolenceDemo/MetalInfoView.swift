import SwiftUI

struct MetalInfoView: View {
    @State
    private var output: String = ""

    var body: some View {
        Form {
            Text("Metal Info")
            Text(output)

            // UltraviolenceDemo.app/Contents/Resources/Ultraviolence_UltraviolenceExamples.bundle

        }
        .task {
            let examplesBundleURL = Bundle.main.resourceURL!.appendingPathComponent("Ultraviolence_UltraviolenceExamples.bundle")
            let examplesBundle = Bundle(url: examplesBundleURL)!
            let debugMetalLibURL = examplesBundle.url(forResource: "debug", withExtension: "metallib")
            let defaultMetalLibURL = examplesBundle.url(forResource: "debug", withExtension: "metallib")

            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["xcrun", "metal-nm", debugMetalLibURL!.path]
            let pipe = Pipe()
            p.standardOutput = pipe
            try! p.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8)!
        }
    }
}
