import simd
import SwiftUI

public struct WorldView<Content: View>: View {
    @Binding
    var projection: any ProjectionProtocol

    @Binding
    private var cameraMatrix: simd_float4x4

    @Binding
    private var targetMatrix: simd_float4x4?

    var content: Content

    @State
    private var cameraMode: CameraMode = .free

    @State
    private var freeCameraController: CameraController = .turntable

    public init(projection: Binding<any ProjectionProtocol>, cameraMatrix: Binding<simd_float4x4>, targetMatrix: Binding<simd_float4x4?> = .constant(nil), content: @escaping () -> Content) {
        self._projection = projection
        self._cameraMatrix = cameraMatrix
        self._targetMatrix = targetMatrix
        self.content = content()
    }

    public var body: some View {
        VStack {
            content
                .modifier(enabled: freeCameraController == .turntable, TurntableCameraController(constraint: initialTurntableControllerConstraint, transform: $cameraMatrix))
            HStack {
                Picker("Mode", selection: $cameraMode) {
                    Text("Free").tag(CameraMode.free)
                    ForEach(CameraAngle.allCases, id: \.self) { angle in
                        Text("\(angle)").tag(CameraMode.fixed(angle))
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()

                Picker("Controller", selection: $freeCameraController) {
                    ForEach(CameraController.allCases, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
        }
        .onChange(of: cameraMode) {
            switch cameraMode {
            case .fixed(let cameraAngle):
                cameraMatrix = cameraAngle.matrix
            default:
                break
            }
        }
    }

    var initialTurntableControllerConstraint: TurntableControllerConstraint {
        let target = targetMatrix?.translation ?? .zero
        let camera = cameraMatrix.translation
        let radius = length(target - camera)
        return TurntableControllerConstraint(target: target, radius: radius)
    }
}

public enum CameraController: Hashable, CaseIterable {
    case turntable
    case arcball
    case flight
    case walk
    case hover
    case pan
}

public enum CameraMode: Hashable {
    case free
    case fixed(CameraAngle)
}

public enum CameraAngle: Hashable, CaseIterable {
    case top
    case bottom
    case left
    case right
    case front
    case back
}

extension CameraAngle {
    var matrix: simd_float4x4 {
        switch self {
        case .top:
            return look(at: [0, 0, 0], from: [0, 1, 0], up: [0, 0, 1])
        case .bottom:
            return look(at: [0, 0, 0], from: [0, -1, 0], up: [0, 0, -1])
        case .left:
            return look(at: [0, 0, 0], from: [-1, 0, 0], up: [0, 1, 0])
        case .right:
            return look(at: [0, 0, 0], from: [1, 0, 0], up: [0, 1, 0])
        case .front:
            return look(at: [0, 0, 0], from: [0, 0, 1], up: [0, 1, 0])
        case .back:
            return look(at: [0, 0, 0], from: [0, 0, -1], up: [0, 1, 0])
        }
    }
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
