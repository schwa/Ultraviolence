import GeometryLite3D
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

// TODO: Deprecate Transforms and use what we do in blinnphong/pbr instead
@available(*, deprecated, message: "Transforms should be deprecated.")
public typealias Transforms = UltraviolenceExampleShaders.Transforms

public extension Transforms {
    init(modelMatrix: simd_float4x4 = .identity, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {
        self.init()

        self.cameraMatrix = cameraMatrix
        self.modelMatrix = modelMatrix
        self.viewMatrix = cameraMatrix.inverse
        self.projectionMatrix = projectionMatrix
        self.modelViewMatrix = viewMatrix * modelMatrix

        self.modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
    }
}

public extension Element {
    func transforms(_ transforms: Transforms) -> some Element {
        self
            .parameter("transforms", functionType: .vertex, value: transforms)
            // TODO: #127 Fix same parameter name with both shaders.
            .parameter("transforms", functionType: .fragment, value: transforms)
    }
}
