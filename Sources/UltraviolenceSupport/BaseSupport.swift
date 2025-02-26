import Metal
import MetalKit

public extension simd_float4x4 {
    init(scale: SIMD3<Float>) {
        self.init([
            [scale.x, 0, 0, 0],
            [0, scale.y, 0, 0],
            [0, 0, scale.z, 0],
            [0, 0, 0, 1]
        ])
    }

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

    var translation: SIMD3<Float> {
        get {
            self[3].xyz
        }
        set {
            self[3].xyz = newValue
        }
    }

    static let identity = simd_float4x4(diagonal: [1, 1, 1, 1])
}

extension SIMD3 {
    var xy: SIMD2<Scalar> {
        get {
            .init(x, y)
        }
        set {
            x = newValue.x
            y = newValue.y
        }
    }
}

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        get {
            .init(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}

// public struct SliderField: View {
//    private let label: String
//
//    @Binding
//    private var value: Float
//
//    private var range: ClosedRange<Float>
//
//    @State
//    private var popupShown = false
//
//    public init(label: String, value: Binding<Float>, in range: ClosedRange<Float>) {
//        self.label = label
//        self._value = value
//        self.range = range
//        self.popupShown = popupShown
//    }
//
//    public var body: some View {
//        HStack {
//            Text("\(label)")
//            Text("\(value)")
//            Button("-") {
//                popupShown = true
//            }
//        }
//        .popover(isPresented: $popupShown) {
//            Slider(value: $value, in: range)
//                .controlSize(.mini)
//                .frame(width: 200)
//                .padding()
//        }
//    }
// }
//
// public extension Color {
//    func float4() throws -> SIMD4<Float> {
//        let cgColor = resolve(in: .init()).cgColor
//        let colorSpace = try CGColorSpace(name: CGColorSpace.linearSRGB).orThrow(.resourceCreationFailure)
//        guard let convertedColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
//            throw UltraviolenceError.resourceCreationFailure
//        }
//        guard let components = convertedColor.components?.map(Float.init) else {
//            throw UltraviolenceError.resourceCreationFailure
//        }
//        return SIMD4<Float>(components[0], components[1], components[2], components[3])
//    }
// }
//
// public struct SIMDColorPicker: View {
//    @Binding
//    var value: SIMD4<Float>
//
//    public init(value: Binding<SIMD4<Float>>) {
//        self._value = value
//    }
//
//    public var body: some View {
//        Grid(alignment: .trailing) {
//            GridRow {
//                Text("Red")
//                Slider(value: $value.x)
//            }
//            GridRow {
//                Text("Green")
//                Slider(value: $value.y)
//            }
//            GridRow {
//                Text("Blue")
//                Slider(value: $value.z)
//            }
//            GridRow {
//                Text("Alpha")
//                Slider(value: $value.w)
//            }
//        }
//        .frame(maxWidth: 80)
//        .controlSize(.mini)
//    }
// }

public extension Optional where Wrapped == String {
    var isTrue: Bool {
        guard let value = self?.lowercased() else {
            return false
        }
        return ["1", "true", "yes"].contains(value)
    }
}

public func isPOD<T>(_ type: T.Type) -> Bool {
    _isPOD(type)
}

public func isPOD<T>(_ value: T) -> Bool {
    _isPOD(T.self)
}

public func isPODArray<T>(_ value: [T]) -> Bool {
    _isPOD(T.self)
}

public func unreachable(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}
