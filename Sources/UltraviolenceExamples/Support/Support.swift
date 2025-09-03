import CoreGraphics
import ImageIO
import Metal
import MetalKit
import ModelIO
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UniformTypeIdentifiers

#if canImport(AppKit)
public extension URL {
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}
#endif


public extension SIMD4<Float> {
    init(color: Color) {
        let resolved = color.resolve(in: .init())
        self = [
            Float(resolved.linearRed),
            Float(resolved.linearGreen),
            Float(resolved.linearBlue),
            Float(1.0) // TODO:
        ]
    }
}


public extension ClosedRange where Bound == Angle {
    var degrees: ClosedRange<Double> {
        lowerBound.degrees ... upperBound.degrees
    }
}

struct PopoverButton <Label, Content>: View where Label: View, Content: View {
    var label: () -> Label
    var content: () -> Content

    @State
    private var isPopoverPresented: Bool = false

    var body: some View {
        Button {
            isPopoverPresented.toggle()
        }
        label: {
            label()
        }
        .popover(isPresented: $isPopoverPresented) {
            content()
        }
    }
}

extension PopoverButton where Label == SwiftUI.Label<Text, Image> {
    init(_ titleKey: LocalizedStringKey, systemImage: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(label: { SwiftUI.Label(titleKey, systemImage: systemImage) }, content: content)
    }
}

struct URLPicker <Label>: View where Label: View {
    var label: Label
    var urls: [URL]
    var action: (URL) -> Void

    init(label: () -> Label, urls: [URL], action: @escaping (URL) -> Void) {
        self.label = label()
        self.urls = urls
        self.action = action
    }

    var body: some View {
        #if os(macOS)
        MenuButton(label: label) {
            ForEach(urls, id: \.self) { url in
                Button(url.lastPathComponent) {
                    action(url)
                }
            }
        }
        #endif
    }
}

extension URLPicker {
    init(label: () -> Label, rootURL: URL, utiTypes: [UTType], action: @escaping (URL) -> Void) {
        let urls = (FileManager().enumerator(at: rootURL, includingPropertiesForKeys: [.contentTypeKey])?.compactMap { $0 as? URL } ?? [])
            .filter { url in
                guard let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                    return false
                }
                return utiTypes.contains { contentType.conforms(to: $0) }
            }
        self.init(label: label, urls: urls, action: action)
    }
}

extension URLPicker where Label == Text {
    init(title titleKey: LocalizedStringKey, rootURL: URL, utiTypes: [UTType], action: @escaping (URL) -> Void) {
        self.init(label: { Text(titleKey) }, rootURL: rootURL, utiTypes: utiTypes, action: action)
    }
}
