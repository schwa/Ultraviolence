#if canImport(AppKit)
import DemoKit
import SwiftUI
import Ultraviolence

public struct OffscreenDemoView: View {
    @State
    private var result: Result<CGImage, Error>?

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        ZStack {
            Color.black
            if case let .success(image) = result {
                Image(nsImage: NSImage(cgImage: image, size: .zero))
                    .resizable()
            }
        }
        .overlay(alignment: .bottom) {
            Group {
                if case let .success(image) = result {
                    Text(verbatim: String(describing: image))
                }
                if case let .failure(error) = result {
                    Text(verbatim: "Failure: \(String(describing: error))")
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding()
        }
        .task {
            do {
                let root = RedTriangle()

                let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
                result = .success(try offscreenRenderer.render(root).cgImage)
            }
            catch {
                result = .failure(error)
            }
        }
    }
}

extension OffscreenDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Offscreen Rendering",
            description: "Render-to-texture demonstration showing offscreen rendering capabilities",
            keywords: ["offscreen", "render-to-texture"],
            )
    }
}
#endif
