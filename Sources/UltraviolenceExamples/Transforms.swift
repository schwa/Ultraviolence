import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public typealias Transforms = UltraviolenceExampleShaders.Transforms

public extension Transforms {
    init(modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {
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

extension Element {
    func blinnPhongTransforms(_ transforms: Transforms) throws -> some Element {
        self
            .parameter("transforms", value: transforms, functionType: .vertex)
            .parameter("transforms_f", value: transforms, functionType: .fragment)
    }
}
