import simd
import SwiftUI
import UltraviolenceExamples
import UltraviolenceSupport

public struct WorldView<Content: View>: View {
    var content: (_ projection: any ProjectionProtocol, _ cameraMatrix: simd_float4x4) -> Content
    var projection: any ProjectionProtocol

    @State
    private var cameraController: CameraControllerModifier.CameraController = .arcball

    @State
    private var cameraMatrix: simd_float4x4 = .identity

    public init(projection: any ProjectionProtocol = PerspectiveProjection(),
                @ViewBuilder content: @escaping (_ projection: any ProjectionProtocol, _ cameraMatrix: simd_float4x4) -> Content) {
        self.projection = projection
        self.content = content
    }

    public var body: some View {
        content(projection, cameraMatrix)
            .cameraController(cameraMatrix: $cameraMatrix)
    }
}

struct CameraControllerModifier: ViewModifier {
    enum CameraController: CaseIterable {
        case arcball
        case sliders
    }

    @Binding
    var cameraMatrix: simd_float4x4

    @State
    var rotation: simd_quatf = .identity

    @State
    var cameraController: CameraController?

    func body(content: Content) -> some View {
        Group {
            switch cameraController {
            case .none:
                content
            case .arcball:
                content.arcBallRotationModifier(rotation: $rotation, radius: 1)
            case .sliders:
                content.slidersOverlayCameraController(rotation: $rotation)
            }
        }
        .onChange(of: rotation) {
            cameraMatrix = .init(rotation)
        }
        .toolbar {
            Picker("Camera Controller", selection: $cameraController) {
                Text("None").tag(Optional<CameraController>.none)
                ForEach(Array(CameraController.allCases.enumerated()), id: \.1) { _, value in
                    Text(value.description).tag(value).keyboardShortcut(value.keyboardShortcut)
                }
            }
        }
    }
}

extension CameraControllerModifier.CameraController: CustomStringConvertible {
    var description: String {
        switch self {
        case .arcball:
            return "Arcball"
        case .sliders:
            return "Sliders"
        }
    }
}

extension CameraControllerModifier.CameraController {
    var keyboardShortcut: KeyboardShortcut? {
        switch self {
        case .arcball:
            return KeyboardShortcut(KeyEquivalent("1"), modifiers: .command)
        case .sliders:
            return KeyboardShortcut(KeyEquivalent("2"), modifiers: .command)
        }
    }
}

extension View {
    func cameraController(cameraMatrix: Binding<simd_float4x4>) -> some View {
        modifier(CameraControllerModifier(cameraMatrix: cameraMatrix))
    }
}

struct SlidersOverlayCameraController: ViewModifier {
    @State
    var pitch: Angle = .zero

    @State
    var yaw: Angle = .zero

    @Binding
    var rotation: simd_quatf

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                VStack {
                    HStack {
                        Slider(value: $pitch.degrees, in: -90...90) { Text("Pitch") }
                        TextField("Pitch", value: $pitch.degrees, formatter: NumberFormatter())
                    }
                    HStack {
                        Slider(value: $yaw.degrees, in: 0...360) { Text("Yaw") }
                        TextField("Yaw", value: $yaw.degrees, formatter: NumberFormatter())
                    }
                }
                .controlSize(.small)
                .frame(maxWidth: 320)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
            .onChange(of: [yaw, pitch], initial: true) {
                let yaw = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0])
                let pitch = simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
                rotation = yaw * pitch
            }
    }
}

extension View {
    func slidersOverlayCameraController(rotation: Binding<simd_quatf>) -> some View {
        modifier(SlidersOverlayCameraController(rotation: rotation))
    }
}
