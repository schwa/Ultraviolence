import DemoKit
import SwiftUI
import UltraviolenceExamples

struct ContentView: View {
    var body: some View {
        DemoPickerView(demos: [
            GaussianSplatDemoView.self,
            BlinnPhongDemoView.self,
            GridShaderDemoView.self,
            SkyboxDemoView.self,
            TriangleDemoView.self,
            OffscreenDemoView.self,
            ComputeDemoView.self,

            // "Complex" Demos
            MetalFXDemoView.self,
            MixedDemoView.self,
            BouncingTeapotsDemoView.self,
            StencilDemoView.self,
            LUTDemoView.self

            // TODO: SYSTEM - these crash
            // GameOfLifeDemoView.self,
        ])
    }
}

#Preview {
    ContentView()
}
