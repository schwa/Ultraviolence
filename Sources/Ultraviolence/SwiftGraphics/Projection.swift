import simd
import SwiftUI

public protocol ProjectionProtocol: Equatable, Sendable {
    func projectionMatrix(for viewSize: SIMD2<Float>) -> simd_float4x4
}

public struct PerspectiveProjection: ProjectionProtocol {
    public var verticalAngleOfView: Angle
    public var zClip: ClosedRange<Float>

    public init(verticalAngleOfView: Angle = .degrees(90), zClip: ClosedRange<Float> = 0.01 ... 1_000) {
        self.verticalAngleOfView = verticalAngleOfView
        self.zClip = zClip
    }

    public func projectionMatrix(for viewSize: SIMD2<Float>) -> simd_float4x4 {
        let aspectRatio = viewSize.x / viewSize.y
        return .perspective(aspectRatio: aspectRatio, fovy: Float(verticalAngleOfView.radians), near: zClip.lowerBound, far: zClip.upperBound)
    }

    public func horizontalAngleOfView(aspectRatio: Double) -> Angle {
        let fovy = verticalAngleOfView.radians
        let fovx = 2 * atan(tan(fovy / 2) * aspectRatio)
        return Angle(radians: fovx)
    }
}

// TODO: Too much duplication here. Deprecate what isn't used.

public extension simd_float4x4 {
    static func perspective(aspectRatio: Float, fovy: Float, near: Float, far: Float) -> Self {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspectRatio
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange

        let P: SIMD4<Float> = [xScale, 0, 0, 0]
        let Q: SIMD4<Float> = [0, yScale, 0, 0]
        let R: SIMD4<Float> = [0, 0, zScale, -1]
        let S: SIMD4<Float> = [0, 0, wzScale, 0]

        return simd_float4x4([P, Q, R, S])
    }
}
