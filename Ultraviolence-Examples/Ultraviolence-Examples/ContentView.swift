import DemoKit
import SwiftUI
import UltraviolenceExamples

struct ContentView: View {

    let demos: [any DemoView.Type]

    init() {
        var demos: [any DemoView.Type] = [
            EmptyView.self,
            GaussianSplatDemoView.self,
            BlinnPhongDemoView.self,
            GridShaderDemoView.self,
            SkyboxDemoView.self,
            TriangleDemoView.self,
            ComputeDemoView.self,
            DepthDemoView.self,

            // "Complex" Demos
            MetalFXDemoView.self,
            MixedDemoView.self,
            BouncingTeapotsDemoView.self,
            StencilDemoView.self,
            LUTDemoView.self,

            GameOfLifeDemoView.self,
            AppleEventLogoDemoView.self,
        ]

#if os(macOS)
        demos += [
            OffscreenDemoView.self
        ]
#endif

        self.demos = demos
    }

    var body: some View {
        DemoPickerView(demos: demos)
    }
}

#Preview {
    ContentView()
}
