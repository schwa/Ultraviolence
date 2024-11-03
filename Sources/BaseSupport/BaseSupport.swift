import MetalKit
import Metal
import SwiftUI

public extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self.init([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [translation.x, translation.y, translation.z, 1]
        ])
    }

    init(yRotation: Angle) {
        let radians = Float(yRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, 0, s, 0],
            [0, 1, 0, 0],
            [-s, 0, c, 0],
            [0, 0, 0, 1]
        ])
    }

    init(zRotation: Angle) {
        let radians = Float(zRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, -s, 0, 0],
            [s, c, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ])
    }

    static let identity = simd_float4x4(diagonal: [1, 1, 1, 1])
}

public struct SliderField: View {

    let label: String

    @Binding
    var value: Float

    var range: ClosedRange<Float>

    @SwiftUI.State
    var popupShown = false

    public init(label: String, value: Binding<Float>, in range: ClosedRange<Float>) {
        self.label = label
        self._value = value
        self.range = range
        self.popupShown = popupShown
    }

    public var body: some View {
        HStack {
            Text("\(label)")
            Text("\(value)")
            Button("-") {
                popupShown = true
            }
        }
        .popover(isPresented: $popupShown) {
            Slider(value: $value, in: range)
            .controlSize(.mini)
            .frame(width: 200)
            .padding()
        }
    }
}

public extension Color {
    func float4() -> SIMD4<Float> {
        let cgColor = resolve(in: .init()).cgColor
        let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
        guard let convertedColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            fatalError()
        }
        guard let components = convertedColor.components?.map(Float.init) else {
            fatalError()
        }
        return SIMD4<Float>(components[0], components[1], components[2], components[3])
    }
}

public struct SIMDColorPicker: View {
    @Binding
    var value: SIMD4<Float>

    public init(value: Binding<SIMD4<Float>>) {
        self._value = value
    }

    public var body: some View {
        Grid(alignment: .trailing) {
            GridRow {
                Text("Red")
                Slider(value: $value.x)
            }
            GridRow {
                Text("Green")
                Slider(value: $value.y)
            }
            GridRow {
                Text("Blue")
                Slider(value: $value.z)
            }
            GridRow {
                Text("Alpha")
                Slider(value: $value.w)
            }
        }
        .frame(maxWidth: 80)
        .controlSize(.mini)
    }

}

