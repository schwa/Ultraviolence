import SwiftUI

#if os(macOS)
public struct ViewAdaptor<ViewType>: View where ViewType: NSView {
    let make: () -> ViewType
    let update: (ViewType) -> Void

    public init(make: @escaping () -> ViewType, update: @escaping (ViewType) -> Void) {
        self.make = make
        self.update = update
    }

    public var body: some View {
        Representation(make: make, update: update)
    }

    struct Representation: NSViewRepresentable {
        let make: () -> ViewType
        let update: (ViewType) -> Void

        func makeNSView(context: Context) -> ViewType {
            make()
        }

        func updateNSView(_ nsView: ViewType, context: Context) {
            update(nsView)
        }
    }
}

#elseif os(iOS) || os(tvOS)
public struct ViewAdaptor<ViewType>: View where ViewType: UIView {
    let make: () -> ViewType
    let update: (ViewType) -> Void

    public init(make: @escaping () -> ViewType, update: @escaping (ViewType) -> Void) {
        self.make = make
        self.update = update
    }

    public var body: some View {
        Representation(make: make, update: update)
    }

    struct Representation: UIViewRepresentable {
        let make: () -> ViewType
        let update: (ViewType) -> Void

        func makeUIView(context: Context) -> ViewType {
            make()
        }

        func updateUIView(_ uiView: ViewType, context: Context) {
            update(uiView)
        }
    }
}
#endif
