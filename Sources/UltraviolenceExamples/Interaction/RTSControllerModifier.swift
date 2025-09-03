import Combine
import GameController
import Observation
import simd
import SwiftUI
import UltraviolenceUI
import UltraviolenceSupport

public struct RTSControllerModifier: ViewModifier {
    @Binding
    var cameraMatrix: simd_float4x4

    var floorPlane: Plane

    @State
    var controller: RTSController?

    public init(cameraMatrix: Binding<simd_float4x4>, floorPlane: Plane = .init(point: .zero, normal: [0, 1, 0])) {
        self._cameraMatrix = cameraMatrix
        self.floorPlane = floorPlane
    }

    public func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            content
                .onChange(of: timeline.date) { _, _ in
                    controller?.update()
                }
        }
        #if os(macOS)
        .modifier(IgnoreKeysViewModifier())
        #endif
        .focusable()
        .focusEffectDisabled()
        .onChange(of: controller?.cameraMatrix) {
            if let controller {
                cameraMatrix = controller.cameraMatrix
            }
        }
        .onAppear {
            controller = RTSController(cameraMatrix: cameraMatrix, floorPlane: floorPlane)
        }
    }
}

public struct Plane {
    public var point: SIMD3<Float>
    public var normal: SIMD3<Float>

    public init(point: SIMD3<Float>, normal: SIMD3<Float>) {
        self.point = point
        self.normal = normal
    }
}

@Observable
@MainActor
internal class RTSController {
    var input = RTSControllerInput.shared
    var cameraMatrix: simd_float4x4
    var floorPlane: Plane

    var yaw: AngleF = .degrees(0)
    var pitch: AngleF = .degrees(0)
    var position: SIMD3<Float>

    var movementMaxSpeed: Float = 1
    var rotationMaxSpeed: AngleF = .degrees(2)

    init(cameraMatrix: simd_float4x4, floorPlane: Plane) {
        self.cameraMatrix = cameraMatrix
        self.floorPlane = floorPlane
        //
        // self.direction = ???
        self.position = cameraMatrix.translation
    }

    deinit {
        print("DEINIT)")
    }

    func update() {
        let movementState = input.getCurrentActions()
        if movementState.contains(.moveForwards) {
            position += simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]).act([0, 0, -movementMaxSpeed])
        }
        if movementState.contains(.moveBackwards) {
            position += simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]).act([0, 0, movementMaxSpeed])
        }
        if movementState.contains(.moveLeft) {
            position += simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]).act([-movementMaxSpeed, 0, 0])
        }
        if movementState.contains(.moveRight) {
            position += simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]).act([movementMaxSpeed, 0, 0])
        }
        if movementState.contains(.rotateLeft) {
            yaw += rotationMaxSpeed
        }
        if movementState.contains(.rotateRight) {
            yaw -= rotationMaxSpeed
        }
        if movementState.contains(.tiltUp) {
            pitch += rotationMaxSpeed
        }
        if movementState.contains(.tiltDown) {
            pitch -= rotationMaxSpeed
        }

        self.cameraMatrix = float4x4(translation: position) * float4x4(simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]))
            * float4x4(simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0]))
    }
}

@MainActor
internal class RTSControllerInput {
    static let shared = RTSControllerInput()

    var keyboard: GCKeyboard?

    var currentActions: Set<Action> = []

    enum Action {
        case moveForwards
        case moveBackwards
        case moveLeft
        case moveRight
        case rotateLeft
        case rotateRight
        case tiltUp
        case tiltDown
        case zoomIn
        case zoomOut
    }

    let keyMap: [Action: [GCKeyCode]] = [
        .moveForwards: [.keyW, .upArrow],
        .moveBackwards: [.keyS, .downArrow],
        .moveLeft: [.keyA, .leftArrow],
        .moveRight: [.keyD, .rightArrow],
        .rotateLeft: [.keyQ],
        .rotateRight: [.keyE],
        .tiltUp: [.keyR],
        .tiltDown: [.keyF],
        .zoomIn: [.keyT],
        .zoomOut: [.keyG]
    ]
    let inverseKeyMap: [GCKeyCode: Action]

    init() {
        self.keyboard = GCKeyboard.coalesced
        self.inverseKeyMap = Dictionary(uniqueKeysWithValues: keyMap.flatMap { action, keyCodes in
            keyCodes.map { keyCode in
                (keyCode, action)
            }
        })

        Task {
            print("Looking for keyboard")
            for await notification in NotificationCenter.default.notifications(named: .GCKeyboardDidConnect) {
                print("Keyboard connected")
                guard let keyboard = notification.object as? GCKeyboard else {
                    continue
                }
                self.foundKeyboard(keyboard)
                break
            }
        }
    }

    func getCurrentActions() -> Set<Action> {
        currentActions
    }

    func gotKey(keycode: GCKeyCode, isPressed: Bool) {
        guard let action = inverseKeyMap[keycode] else {
            return
        }
        if isPressed {
            currentActions.insert(action)
        }
        else {
            currentActions.remove(action)
        }
    }

    func foundKeyboard(_ keyboard: GCKeyboard) {
        if let coalesced = GCKeyboard.coalesced {
            self.keyboard = coalesced
        }
        else if self.keyboard == nil {
            self.keyboard = keyboard
        }
        self.keyboard?.keyboardInput?.keyChangedHandler = { [weak self] _, _, keycode, isPressed in
            guard let self else {
                return
            }
            self.gotKey(keycode: keycode, isPressed: isPressed)
        }
    }
}

#if os(macOS)
internal struct IgnoreKeysViewModifier: ViewModifier {
    class _View: NSView {
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            if event.modifierFlags.contains(.command) {
                return false
            }
            return true
        }
    }

    func body(content: Content) -> some View {
        ViewAdaptor<_View> {
            let hostingView = NSHostingView(rootView: content)
            hostingView.autoresizingMask = [.width, .height]
            let root = _View()
            root.addSubview(hostingView)
            return root
        } update: { _ in
            // This line is intentionally left blank
        }
    }
}
#endif
