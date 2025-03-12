import CoreGraphics
import simd

public protocol ProjectionProtocol: Equatable, Sendable {
    func projectionMatrix(aspectRatio: Float) -> simd_float4x4
}

public extension ProjectionProtocol {
    func projectionMatrix(for viewSize: SIMD2<Float>) -> simd_float4x4 {
        let aspectRatio = viewSize.x / viewSize.y
        return self.projectionMatrix(aspectRatio: aspectRatio)
    }

    func projectionMatrix(for viewSize: CGSize) -> simd_float4x4 {
        projectionMatrix(for: .init(viewSize))
    }
}

public struct PerspectiveProjection: ProjectionProtocol {
    public var verticalAngleOfView: AngleF
    public var zClip: ClosedRange<Float>

    public init(verticalAngleOfView: AngleF = .degrees(90), zClip: ClosedRange<Float> = 0.01 ... 1_000) {
        self.verticalAngleOfView = verticalAngleOfView
        self.zClip = zClip
    }

    public func projectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        .perspective(aspectRatio: aspectRatio, fovy: Float(verticalAngleOfView.radians), near: zClip.lowerBound, far: zClip.upperBound)
    }

    public func horizontalAngleOfView(aspectRatio: Float) -> AngleF {
        let fovy = verticalAngleOfView.radians
        let fovx = 2 * atan(tan(fovy / 2) * aspectRatio)
        return AngleF(radians: fovx)
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

// TODO: Make an extension on simd_float4x4 instead.
public func look(at target: SIMD3<Float>, from eye: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let forward: SIMD3<Float> = (target - eye).normalized

    // Side = forward x up
    let side = simd_cross(forward, up).normalized

    // Recompute up as: up = side x forward
    let up_ = simd_cross(side, forward).normalized

    var matrix2: simd_float4x4 = .identity

    matrix2[0] = SIMD4<Float>(side, 0)
    matrix2[1] = SIMD4<Float>(up_, 0)
    matrix2[2] = SIMD4<Float>(-forward, 0)
    matrix2[3] = [0, 0, 0, 1]

    return simd_float4x4(translation: eye) * matrix2
}

extension SIMD3<Float> {
    var normalized: SIMD3<Float> {
        simd_normalize(self)
    }
}
