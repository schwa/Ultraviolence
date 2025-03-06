import Metal
import simd
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct ShadowMapRenderPass <Content>: Element where Content: Element {
    var lightPosition: SIMD3<Float>
    var shadowCubeTexture: MTLTexture
    var content: (_ cameraMatrix: float4x4, _ projectionMatrix: float4x4) throws -> Content
    var depthTexture: MTLTexture

    init(lightPosition: SIMD3<Float>, shadowCubeTexture: MTLTexture, @ElementBuilder content: @escaping (_ cameraMatrix: float4x4, _ projectionMatrix: float4x4) throws -> Content) {
        self.lightPosition = lightPosition
        self.shadowCubeTexture = shadowCubeTexture
        self.content = content

        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.width = 1_024
        descriptor.height = 1_024
        descriptor.pixelFormat = .depth32Float
        descriptor.usage = [.renderTarget]
        descriptor.storageMode = .memoryless

        let device = MTLCreateSystemDefaultDevice()!
        depthTexture = device.makeTexture(descriptor: descriptor)!
    }

    var body: some Element {
        get throws {
            let projectionMatrix = PerspectiveProjection(verticalAngleOfView: .degrees(90), zClip: 0.001 ... 100.0).projectionMatrix(aspectRatio: 1)
            ForEach(Array(0..<6), id: \.self) { face in
                let cameraMatrix = cameraMatrixForShadowMap(face: face, lightPosition: lightPosition)
                try RenderPass {
                    try content(cameraMatrix, projectionMatrix)
                }
                .renderPassDescriptorModifier { descriptor in
                    descriptor.colorAttachments[0].loadAction = .clear
                    descriptor.colorAttachments[0].storeAction = .store
                    descriptor.colorAttachments[0].texture = shadowCubeTexture
                    descriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
                    descriptor.colorAttachments[0].slice = face

                    descriptor.depthAttachment.texture = depthTexture
                    descriptor.depthAttachment.loadAction = .clear
                    descriptor.depthAttachment.storeAction = .dontCare
                    descriptor.depthAttachment.clearDepth = 1
                }
                .depthCompare(function: .less, enabled: true)
            }
        }
    }
}

func cameraMatrixForShadowMap(face: Int, lightPosition: SIMD3<Float>) -> float4x4 {
    let target: SIMD3<Float>
    let up: SIMD3<Float>

    switch face {
    case 0: // +X
        target = lightPosition + SIMD3<Float>(1, 0, 0)
        up = SIMD3<Float>(0, 1, 0) // FIXED: Should be +Y
    case 1: // -X
        target = lightPosition + SIMD3<Float>(-1, 0, 0)
        up = SIMD3<Float>(0, 1, 0) // FIXED: Should be +Y
    case 2: // +Y
        target = lightPosition + SIMD3<Float>(0, 1, 0)
        up = SIMD3<Float>(0, 0, 1) // CORRECT
    case 3: // -Y
        target = lightPosition + SIMD3<Float>(0, -1, 0)
        up = SIMD3<Float>(0, 0, -1) // CORRECT
    case 4: // +Z
        target = lightPosition + SIMD3<Float>(0, 0, 1)
        up = SIMD3<Float>(0, 1, 0) // FIXED: Should be +Y
    case 5: // -Z
        target = lightPosition + SIMD3<Float>(0, 0, -1)
        up = SIMD3<Float>(0, 1, 0) // FIXED: Should be +Y
    default:
        fatalError("Invalid face index for cube map (should be 0-5)")
    }

    return lookAtMatrix(eye: lightPosition, target: target, up: up)
}

func lookAtMatrix(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
    let forward = normalize(target - eye)
    let right = normalize(cross(forward, up))
    let newUp = cross(right, forward)

    return float4x4(
        SIMD4<Float>(right.x, right.y, right.z, 0),
        SIMD4<Float>(newUp.x, newUp.y, newUp.z, 0),
        SIMD4<Float>(forward.x, forward.y, forward.z, 0), // FIXED: Do NOT negate forward
        SIMD4<Float>(-dot(right, eye), -dot(newUp, eye), -dot(forward, eye), 1) // FIXED: Negate forward dot product
    )
}
