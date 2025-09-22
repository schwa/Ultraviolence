import CoreGraphics
import ImageIO
import Metal
import MetalKit
import ModelIO
import simd
import SwiftUI
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
            Float(resolved.opacity)
        ]
    }
}


extension Color {
    // TODO: Not linear
    var float4: SIMD4<Float> {
        get {
            let resolved = self.resolve(in: .init())
            return [Float(resolved.red), Float(resolved.green), Float(resolved.blue), Float(resolved.opacity)]
        }
        set {
            self = Color(red: Double(newValue[0]), green: Double(newValue[1]), blue: Double(newValue[2]), opacity: Double(newValue[3]))
        }
    }
}

extension SIMD4<Float> {
    var color: Color {
        get {
            // Construct a SwiftUI Color from the SIMD components
            Color(red: Double(self.x), green: Double(self.y), blue: Double(self.z), opacity: Double(self.w))
        }
        set {
            let resolved = newValue.resolve(in: .init())
            self = [Float(resolved.red), Float(resolved.green), Float(resolved.blue), Float(resolved.opacity)]
        }
    }
}

extension SIMD3<Float> {
    // TODO: Not linear
    var color: Color {
        get {
            Color(red: Double(self.x), green: Double(self.y), blue: Double(self.z))
        }
        set {
            let resolved = newValue.resolve(in: .init())
            self = [Float(resolved.red), Float(resolved.green), Float(resolved.blue)]
        }
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

public func lookAtMatrix(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
    let forward = normalize(target - eye)
    let right = normalize(cross(forward, up))
    let newUp = cross(right, forward)

    return float4x4(
        SIMD4<Float>(right.x, right.y, right.z, 0),
        SIMD4<Float>(newUp.x, newUp.y, newUp.z, 0),
        SIMD4<Float>(forward.x, forward.y, forward.z, 0), // FIXED: Do NOT negate forward
        SIMD4<Float>(-dot(right, eye), -dot(newUp, eye), -dot(forward, eye), 1) // FIXED: Negate forward dot product
    )
}


extension View {
    @ViewBuilder
    func modifier(enabled: Bool, _ modifier: (some ViewModifier)) -> some View {
        if enabled {
            self.modifier(modifier)
        }
        else {
            self
        }
    }
}
