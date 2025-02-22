#if canImport(AppKit)
import SwiftUI
import Ultraviolence
import UltraviolenceExamples

struct OffscreenDemoView: View {
    @State
    private var image: Image?

    var body: some View {
        ZStack {
            Color.black
            image
        }
        .task {
            do {
                let root = RedTriangle()
                let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
                let cgImage = try offscreenRenderer.render(root).cgImage
                image = Image(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)))
            }
            catch {
                print(error)
            }
        }
    }
}

extension OffscreenDemoView: DemoView {
}
#endif
