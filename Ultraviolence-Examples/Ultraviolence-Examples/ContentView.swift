import DemoKit
import SwiftUI
import UltraviolenceExamples

struct ContentView: View {
    var body: some View {
        DemoPickerView(demos: allDemos)
    }
}

#Preview {
    ContentView()
}
