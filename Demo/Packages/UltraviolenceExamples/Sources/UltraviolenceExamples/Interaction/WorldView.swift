import simd
import SwiftUI
import UltraviolenceSupport

public struct WorldView<Content: View>: View {
    @Binding
    var projection: any ProjectionProtocol

    @Binding
    private var cameraMatrix: simd_float4x4

    @Binding
    private var targetMatrix: simd_float4x4?

    var content: Content

    @State
    private var cameraController: CameraControllerModifier.CameraController = .arcball

    @State
    private var cameraMode: CameraMode = .free

    public init(projection: Binding<any ProjectionProtocol>, cameraMatrix: Binding<simd_float4x4>, targetMatrix: Binding<simd_float4x4?> = .constant(nil), content: @escaping () -> Content) {
        self._projection = projection
        self._cameraMatrix = cameraMatrix
        self._targetMatrix = targetMatrix
        self.content = content()
    }

    public var body: some View {
        VStack {
            content
            //                .cameraController(cameraMatrix: $cameraMatrix)

            Picker("Mode", selection: $cameraMode) {
                Text("Free").tag(CameraMode.free)
                Text("Top").tag(CameraMode.fixed(.top))
                Text("Bottom").tag(CameraMode.fixed(.bottom))
                Text("Left").tag(CameraMode.fixed(.left))
                Text("Right").tag(CameraMode.fixed(.right))
                Text("Front").tag(CameraMode.fixed(.front))
                Text("Back").tag(CameraMode.fixed(.back))
            }
            .pickerStyle(.menu)
            .fixedSize()
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
}

public enum CameraMode: Hashable {
    case free
    case fixed(CameraAngle)
}

public enum CameraAngle: Hashable {
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
