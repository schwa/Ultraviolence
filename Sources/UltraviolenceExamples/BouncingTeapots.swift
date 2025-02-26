import MetalKit
import simd
import SwiftUI
import Ultraviolence
internal import UltraviolenceSupport

public struct BouncingTeapotsDemoView: View {
    @State
    private var simulation = TeapotSimulation(count: 60)

    @State
    private var lastUpdate: Date?

    let cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])
    let mesh: MTKMesh = .teapot()

    public var body: some View {
        TimelineView(.animation) { timeline in
            let colors = simulation.teapots.map(\.color)
            let modelMatrices = simulation.teapots.map(\.matrix)
            RenderView {
                EnvironmentReader(keyPath: \.drawableSize) { drawableSize in
                    let projectionMatrix = PerspectiveProjection().projectionMatrix(for: drawableSize.orFatalError())
                    try RenderPass {
                        try LambertianShaderInstanced(colors: colors, modelMatrices: modelMatrices, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, lightDirection: [-1, -2, -1]) {
                            Draw { encoder in
                                encoder.setVertexBuffers(of: mesh)
                                encoder.draw(mesh, instanceCount: simulation.teapots.count)
                            }
                        }
                    }
                    .depthCompare(function: .less, enabled: true)
                    .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
                }
            }
            .onChange(of: timeline.date) {
                let now = timeline.date
                if let lastUpdate {
                    simulation.step(duration: now.timeIntervalSince(lastUpdate))
                }
                lastUpdate = now
            }
        }
    }
}

struct Teapot {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var rotationVelocity: simd_quatf
    var velocity: SIMD3<Float>
    var color: SIMD3<Float>
}

struct TeapotSimulation {
    var teapots: [Teapot] = []
    var boundingBox: BoundingBox = .init(min: [-4, 0, -4], max: [4, 4, 4])

    init(count: Int) {
        // create random teapots
        teapots = (0..<count).map { _ in
            Teapot(
                position: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)],
                rotation: simd_quatf(angle: .init(Float.random(in: 0...(2 * .pi))), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                rotationVelocity: simd_quatf(angle: .init(Float.random(in: -1...1)), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                velocity: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)] * 5,
                color: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
        }
    }

    mutating func step(duration: TimeInterval) {
        teapots = teapots.map { teapot in
            var teapot = teapot
            teapot.position += teapot.velocity * Float(duration)
            if teapot.position.x < boundingBox.min.x {
                teapot.position.x = boundingBox.min.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.x > boundingBox.max.x {
                teapot.position.x = boundingBox.max.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.y < boundingBox.min.y {
                teapot.position.y = boundingBox.min.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.y > boundingBox.max.y {
                teapot.position.y = boundingBox.max.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.z < boundingBox.min.z {
                teapot.position.z = boundingBox.min.z
                teapot.velocity.z = -teapot.velocity.z
            }
            if teapot.position.z > boundingBox.max.z {
                teapot.position.z = boundingBox.max.z
                teapot.velocity.z = -teapot.velocity.z
            }
            teapot.rotation = simd_slerp(teapot.rotation, teapot.rotation * teapot.rotationVelocity, Float(duration))
            return teapot
        }
    }
}

struct BoundingBox {
    var min: SIMD3<Float>
    var max: SIMD3<Float>
}



extension Teapot {
    var matrix: simd_float4x4 {
        var matrix = simd_float4x4.identity
        matrix *= simd_float4x4(translation: position) // Apply translation last
        matrix *= simd_float4x4(rotation)             // Apply rotation second
        matrix *= simd_float4x4(scale: [0.2, 0.2, 0.2]) // Apply scaling first
        return matrix
    }
}

public extension MTLRenderCommandEncoder {
    func setVertexBuffers(of mesh: MTKMesh) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
        }
    }

    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            draw(submesh, instanceCount: instanceCount)
        }
    }

    func draw(_ submesh: MTKSubmesh, instanceCount: Int) {
        drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
    }
}

extension MTKMesh {
    static func teapot() -> MTKMesh {
        let device = try MTLCreateSystemDefaultDevice().orFatalError()
        let teapotURL = try Bundle.module.url(forResource: "teapot", withExtension: "obj").orFatalError()
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orFatalError()
        return try! MTKMesh(mesh: mdlMesh, device: device)
    }
}
