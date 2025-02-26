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

    @State
    private var checkerboardColor: Color = .white

    let cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])
    let mesh: MTKMesh = .teapot()
    let sphere: MTKMesh = .sphere(extent: [100, 100, 100], inwardNormals: true)
    let skyboxSampler: MTLSamplerState
    let skyboxTexture: MTLTexture

    public init() {
        print("#INIT#")
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 512, height: 512, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        skyboxTexture = device.makeTexture(descriptor: textureDescriptor).orFatalError()
        let samplerDescriptor = MTLSamplerDescriptor()
        skyboxSampler = device.makeSamplerState(descriptor: samplerDescriptor).orFatalError()
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let colors = simulation.teapots.map(\.color)
            let modelMatrices = simulation.teapots.map(\.matrix)
            RenderView {
                // Render a checkerboard pattern into a texture
                try ComputePass {
                    try CheckerboardKernel(outputTexture: skyboxTexture, checkerSize: [20, 20], backgroundColor: [0, 0, 0, 1], foregroundColor: .init(color: checkerboardColor))
                }
                try RenderPass {
                    EnvironmentReader(keyPath: \.drawableSize) { drawableSize in
                        let projectionMatrix = PerspectiveProjection().projectionMatrix(for: drawableSize.orFatalError())

                        // Draw the checkerboard texture into a skybox
                        try FlatShader(modelMatrix: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, texture: skyboxTexture, sampler: skyboxSampler) {
                            Draw { encoder in
                                encoder.setVertexBuffers(of: sphere)
                                encoder.draw(sphere)
                            }
                        }
                        .vertexDescriptor(MTLVertexDescriptor(sphere.vertexDescriptor))

                        // Teapot party.
                        try LambertianShaderInstanced(colors: colors, modelMatrices: modelMatrices, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, lightDirection: [-1, -2, -1]) {
                            Draw { encoder in
                                encoder.setVertexBuffers(of: mesh)
                                encoder.draw(mesh, instanceCount: simulation.teapots.count)
                            }
                        }
                        .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
                    }
                    .depthCompare(function: .less, enabled: true)
                }
            }
            .onChange(of: timeline.date) {
                let now = timeline.date
                if let lastUpdate {
                    simulation.step(duration: now.timeIntervalSince(lastUpdate))
                }
                lastUpdate = now
            }
            .inspector(isPresented: .constant(true)) {
                Form {
                    ColorPicker("Checkerboard Color", selection: $checkerboardColor)
                }
            }
        }
    }
}

internal struct Teapot {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var rotationVelocity: simd_quatf
    var velocity: SIMD3<Float>
    var color: SIMD3<Float>
}

internal struct TeapotSimulation {
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

internal struct BoundingBox {
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

extension SIMD4<Float> {
    init(color: Color) {
        let resolved = color.resolve(in: .init())
        self = [
            Float(resolved.linearRed),
            Float(resolved.linearGreen),
            Float(resolved.linearBlue),
            Float(1.0) // TODO:
        ]
    }
}
