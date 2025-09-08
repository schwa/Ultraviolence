import SwiftUI
import UltraviolenceExamples
import DemoKit

struct ContentView: View {

    var body: some View {
        DemoPickerView(demos: [
            GaussianSplatDemoView.self,
            BlinnPhongDemoView.self,
            GameOfLifeDemoView.self,
            GridShaderDemoView.self,
            SkyboxDemoView.self,
            MixedDemoView.self,
            TriangleDemoView.self,
            OffscreenDemoView.self,
            ComputeDemoView.self,
            BouncingTeapotsDemoView.self,
            StencilDemoView.self,
            LUTDemoView.self,
            MetalFXDemoView.self,
        ])
    }

}

#Preview {
    ContentView()
}

