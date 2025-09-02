// import simd
// import SwiftUI
//
// internal struct CameraControllerModifier: ViewModifier {
//    enum CameraController: CaseIterable {
//        case arcball
//        case sliders
//    }
//
//    @Binding
//    var cameraMatrix: simd_float4x4
//
//    @State
//    var rotation: simd_quatf = .identity
//
//    @State
//    var cameraController: CameraController?
//
//    func body(content: Content) -> some View {
//        Group {
//            switch cameraController {
//            case .none:
//                content
//            case .arcball:
//                content.arcBallRotationModifier(rotation: $rotation, radius: 1)
//            case .sliders:
//                content.slidersOverlayCameraController(rotation: $rotation)
//            }
//        }
//        .onChange(of: rotation) {
//            cameraMatrix = .init(rotation)
//        }
//        .toolbar {
//            Picker("Camera Controller", selection: $cameraController) {
//                Text("None").tag(Optional<CameraController>.none)
//                ForEach(Array(CameraController.allCases.enumerated()), id: \.1) { _, value in
//                    Text(value.description).tag(value).keyboardShortcut(value.keyboardShortcut)
//                }
//            }
//        }
//    }
// }
//
// extension CameraControllerModifier.CameraController: CustomStringConvertible {
//    var description: String {
//        switch self {
//        case .arcball:
//            return "Arcball"
//        case .sliders:
//            return "Sliders"
//        }
//    }
// }
//
// extension CameraControllerModifier.CameraController {
//    var keyboardShortcut: KeyboardShortcut? {
//        switch self {
//        case .arcball:
//            return KeyboardShortcut(KeyEquivalent("1"), modifiers: .command)
//        case .sliders:
//            return KeyboardShortcut(KeyEquivalent("2"), modifiers: .command)
//        }
//    }
// }
//
// extension View {
//    func cameraController(cameraMatrix: Binding<simd_float4x4>) -> some View {
//        modifier(CameraControllerModifier(cameraMatrix: cameraMatrix))
//    }
// }
