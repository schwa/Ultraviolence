import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

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
        self.modelNormalMatrix = modelMatrix.upperLeft
    }
}

public extension Element {
    func blinnPhongTransforms(_ transforms: Transforms) throws -> some Element {
        self
            .parameter("transforms", value: transforms, functionType: .vertex)
            // TODO: Fix same parameter name with both shaders.
            .parameter("transforms_f", value: transforms, functionType: .fragment)
    }
}
