import Ultraviolence
import UltraviolenceExampleShaders

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
    func transforms(_ transforms: Transforms) -> some Element {
        self
            .parameter("transforms", value: transforms, functionType: .vertex)
            // TODO: #127 Fix same parameter name with both shaders.
            .parameter("transforms", value: transforms, functionType: .fragment)
    }
}
