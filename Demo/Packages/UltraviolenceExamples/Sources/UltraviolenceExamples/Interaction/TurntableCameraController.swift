import simd
import SwiftUI

public struct TurntableCameraController: ViewModifier {
    @State
    private var constraint: TurntableControllerConstraint

    @Binding
    var transform: simd_float4x4

    public init(constraint: TurntableControllerConstraint, transform: Binding<simd_float4x4>) {
        self._constraint = State(initialValue: constraint)
        self._transform = transform
        // TODO: #132 compute pitch yaw from transform
    }

    public func body(content: Content) -> some View {
        content
            .draggableValue($constraint.pitch.degrees, axis: .vertical, scale: 0.1, behavior: constraint.pitchBehavior)
            .draggableValue($constraint.yaw.degrees, axis: .horizontal, scale: 0.1, behavior: constraint.yawBehavior)
            .onChange(of: constraint, initial: true) {
                transform = constraint.transform
            }
    }
}

// MARK: -

public struct TurntableControllerConstraint: Equatable {
    public var target: SIMD3<Float>
    public var radius: Float
    // TODO: #133 Pitch and yaw are NOT constraints and should be in the controller not here.
    public var pitch: Angle = .zero
    public var yaw: Angle = .zero
    public var towards: Bool = true
    public var pitchBehavior: DraggableValueBehavior
    public var yawBehavior: DraggableValueBehavior

    public init(target: SIMD3<Float> = .zero, radius: Float, pitchBehavior: DraggableValueBehavior = .clamping(-90 ... 90), yawBehavior: DraggableValueBehavior = .linear) {
        self.target = target
        self.radius = radius
        self.pitchBehavior = pitchBehavior
        self.yawBehavior = yawBehavior
    }

    public var transform: simd_float4x4 {
        // Convert SwiftUI Angles to radians:
        let rotation = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0]) * simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
        let localPos = SIMD4<Float>(0, 0, radius, 1)
        let rotatedOffset = simd_float4x4(rotation) * localPos
        let other = target + rotatedOffset.xyz
        if towards {
            return look(at: target, from: other, up: [0, 1, 0])
        }
        return look(at: other, from: target, up: [0, 1, 0])
    }
}

public extension simd_float4x4 {
    /// Computes the yaw (rotation about Y-axis) from the transformation matrix.
    /// Assumes no shear and uniform scaling.
    var yaw: Float {
        atan2(columns.0.z, columns.2.z)
    }

    /// Computes the pitch (rotation about X-axis) from the transformation matrix.
    /// Assumes no shear and uniform scaling. Handles gimbal lock cases.
    var pitch: Float {
        let value = -columns.1.z
        return asin(clamp(value, min: -1.0, max: 1.0)) // Clamp to avoid domain errors
    }

    /// Detects if the matrix has shear (i.e., non-orthogonal basis vectors).
    var isShear: Bool {
        let x = SIMD3<Float>(columns.0.x, columns.0.y, columns.0.z)
        let y = SIMD3<Float>(columns.1.x, columns.1.y, columns.1.z)
        let z = SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z)

        // Check if dot products are non-zero (non-orthogonal vectors indicate shear)
        let xyDot = simd_dot(x, y)
        let yzDot = simd_dot(y, z)
        let zxDot = simd_dot(z, x)

        return !isApproximatelyZero(xyDot) || !isApproximatelyZero(yzDot) || !isApproximatelyZero(zxDot)
    }

    /// Detects if the matrix has non-uniform scaling.
    var isNonUniformScale: Bool {
        let scaleX = length(SIMD3<Float>(columns.0.x, columns.0.y, columns.0.z))
        let scaleY = length(SIMD3<Float>(columns.1.x, columns.1.y, columns.1.z))
        let scaleZ = length(SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z))

        // Non-uniform scaling if the scales are not equal
        return !isApproximatelyEqual(scaleX, scaleY) || !isApproximatelyEqual(scaleY, scaleZ)
    }

    /// Helper function to check if a value is approximately zero.
    private func isApproximatelyZero(_ value: Float, epsilon: Float = 1e-5) -> Bool {
        abs(value) < epsilon
    }

    /// Helper function to check if two values are approximately equal.
    private func isApproximatelyEqual(_ a: Float, _ b: Float, epsilon: Float = 1e-5) -> Bool {
        abs(a - b) < epsilon
    }

    /// Helper function to clamp values.
    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.max(min, Swift.min(max, value))
    }
}
