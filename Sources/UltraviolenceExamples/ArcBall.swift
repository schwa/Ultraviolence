import simd
import SwiftUI

internal struct ArcBallRotationModifier: ViewModifier {
    @Binding
    var rotation: simd_quatf

    @State
    private var arcBall: ArcBall

    @State
    var size: CGSize = .zero

    @State
    var startPoint: CGPoint?

    init(rotation: Binding<simd_quatf>, radius: Float) {
        self._rotation = rotation
        self.arcBall = ArcBall(radius: radius)
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let point = convertToArcBallCoordinates(gesture.location, in: gesture.startLocation)
                        if let startPoint {
                            arcBall.updateRotation(to: point)
                        }
                        else {
                            startPoint = gesture.location
                            arcBall.startRotation(at: point)
                        }
                        rotation = arcBall.getRotationQuaternion()
                    }
                    .onEnded { _ in
                        startPoint = nil
                    }
            )
    }

    private func convertToArcBallCoordinates(_ location: CGPoint, in startLocation: CGPoint) -> SIMD2<Float> {
        let x = (2.0 * Float(location.x) / Float(size.width)) - 1.0
        let y = 1.0 - (2.0 * Float(location.y) / Float(size.height)) // Flip y to match screen coordinates
        return SIMD2<Float>(x, y)
    }
}

public extension View {
    func arcBallRotationModifier(rotation: Binding<simd_quatf>, radius: Float) -> some View {
        modifier(ArcBallRotationModifier(rotation: rotation, radius: radius))
    }
}

internal struct ArcBall {
    private var radius: Float
    private var lastVector: SIMD3<Float>
    private var currentQuaternion: simd_quatf

    init(initialRotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1)), radius: Float = 1.0) {
        self.radius = radius
        self.lastVector = SIMD3<Float>(0, 0, 1)  // Start at the "pole" of the sphere
        self.currentQuaternion = initialRotation
    }

    mutating func startRotation(at point: SIMD2<Float>) {
        lastVector = mapPointToSphere(point)
    }

    mutating func updateRotation(to point: SIMD2<Float>) {
        var currentVector = mapPointToSphere(point)

        // **Ensure both vectors are normalized**
        lastVector = simd_normalize(lastVector)
        currentVector = simd_normalize(currentVector)

        let rotationAxis = simd_cross(lastVector, currentVector)
        let dotProduct = simd_dot(lastVector, currentVector)

        // **Ensure dot product is within valid range**
        let clampedDot = max(-1.0, min(1.0, dotProduct))
        let angle = acos(clampedDot)

        if abs(angle) > 0.0001 {  // Avoid small rotations
            let normalizedAxis = simd_normalize(rotationAxis)

            if simd_length(normalizedAxis) > 0.0001 {
                let rotation = simd_quatf(angle: angle, axis: normalizedAxis)
                currentQuaternion = rotation * currentQuaternion
            }
        }

        lastVector = currentVector
    }
    func getRotationQuaternion() -> simd_quatf {
        currentQuaternion
    }

    private func mapPointToSphere(_ point: SIMD2<Float>) -> SIMD3<Float> {
        let lengthSquared = simd_length_squared(point)

        if lengthSquared <= (radius * radius) {
            return SIMD3<Float>(point.x, point.y, sqrt(radius * radius - lengthSquared))
        } else {
            let normalizedPoint = simd_normalize(point)
            return SIMD3<Float>(normalizedPoint.x, normalizedPoint.y, 0.0)
        }
    }
}
