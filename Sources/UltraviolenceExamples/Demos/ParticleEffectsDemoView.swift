import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import GeometryLite3D
import simd
import Metal
import UltraviolenceExampleShaders

public struct ParticleEffectsDemoView: View {
    @State private var projection: any ProjectionProtocol = PerspectiveProjection()
    @State private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 8])
    @State private var drawableSize: CGSize = .zero
    @State private var time: Float = 0
    @State private var frameCount: Int = 0
    @State private var isPaused: Bool = false

    // Particle system parameters
    @State private var particleCount: Int = 5000
    @State private var particleSize: Float = 20.0
    @State private var gravity: SIMD3<Float> = [0, -9.8, 0]
    @State private var emitterType: EmitterType = .fountain
    @State private var emissionRate: Float = 1000

    // Particle buffers
    @State private var particleBuffer: MTLBuffer?
    @State private var emitterBuffer: MTLBuffer?

    enum EmitterType: String, CaseIterable {
        case fountain = "Fountain"
        case explosion = "Explosion"
        case rain = "Rain"
        case fireworks = "Fireworks"
        case tornado = "Tornado"
    }

    public init() {}

    public var body: some View {
        TimelineView(.animation) { context in
            let _ = updateTime()  // Update time on each frame
            WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
                RenderView { context, drawableSize in
                    if let particleBuffer, let emitterBuffer {
                        try Group {
                            // Update particles using compute shader (only when not paused)
                            if !isPaused {
                                try ComputePass {
                                    ParticleUpdateCompute(
                                        particleBuffer: particleBuffer,
                                        emitterBuffer: emitterBuffer,
                                        particleCount: particleCount,
                                        time: time,
                                        gravity: gravity,
                                        emitterType: emitterType,
                                        emissionRate: emissionRate
                                    )
                                }
                            }

                            // Render particles
                            try RenderPass {
                                ParticleRenderPipeline(
                                    particleBuffer: particleBuffer,
                                    particleCount: particleCount,
                                    viewMatrix: cameraMatrix.inverse,
                                    projectionMatrix: projection.projectionMatrix(for: drawableSize),
                                    time: time,
                                    gravity: gravity,
                                    baseSize: particleSize
                                )
                                .depthCompare(function: .less, enabled: true)
                            }
                        }
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .onDrawableSizeChange {
                    drawableSize = $0
                }
                .onAppear {
                    initializeParticles()
                }
                .onChange(of: particleCount) { _, _ in
                    initializeParticles()
                }
                .onChange(of: emitterType) { _, _ in
                    initializeParticles()
                }
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                Text("Particle Effects Demo")
                    .font(.headline)

                Picker("Emitter", selection: $emitterType) {
                    ForEach(EmitterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Label("Particles: \(particleCount)", systemImage: "sparkles")
                Slider(value: Binding(get: { Double(particleCount) }, set: { particleCount = Int($0) }), in: 1000...20000, step: 1000)

                Label("Size: \(particleSize, specifier: "%.1f")", systemImage: "circle.fill")
                Slider(value: $particleSize, in: 5...50)

                Label("Gravity: \(gravity.y, specifier: "%.1f")", systemImage: "arrow.down")
                Slider(value: $gravity.y, in: -10...10)

                Label("Emission: \(Int(emissionRate))/s", systemImage: "sparkle")
                Slider(value: $emissionRate, in: 100...2000)

                HStack {
                    Button(action: { isPaused.toggle() }) {
                        Label(isPaused ? "Resume" : "Pause", systemImage: isPaused ? "play.fill" : "pause.fill")
                    }

                    Button("Reset") {
                        initializeParticles()
                    }
                }
            }
            .frame(width: 300)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }

    private func initializeParticles() {
        let device = MTLCreateSystemDefaultDevice()!

        // Initialize all particles as dead (life = 0)
        var particles: [Particle] = []
        particles.reserveCapacity(particleCount)

        for _ in 0..<particleCount {
            particles.append(Particle(
                position: SIMD3<Float>(0, 0, 0),
                velocity: SIMD3<Float>(0, 0, 0),
                color: SIMD3<Float>(1, 1, 1),
                life: 0,  // Start dead
                size: 1.0
            ))
        }

        // Create particle buffer
        let bufferSize = particles.count * MemoryLayout<Particle>.stride
        particleBuffer = device.makeBuffer(bytes: particles, length: bufferSize, options: [.storageModeShared])
        particleBuffer?.label = "Particle Buffer"

        // Create emitter parameters buffer
        let emitterParams = ParticleEmitterParams(
            position: getEmitterPosition(for: emitterType),
            emitterType: Int32(emitterTypeIndex),
            emissionRate: emissionRate,
            time: 0
        )
        emitterBuffer = device.makeBuffer(bytes: [emitterParams], length: MemoryLayout<ParticleEmitterParams>.stride, options: [.storageModeShared])
        emitterBuffer?.label = "Emitter Buffer"

        time = 0
        frameCount = 0
    }

    private var emitterTypeIndex: Int {
        EmitterType.allCases.firstIndex(of: emitterType) ?? 0
    }

    private func getEmitterPosition(for type: EmitterType) -> SIMD3<Float> {
        switch type {
        case .fountain: return SIMD3<Float>(0, -2, 0)
        case .explosion: return SIMD3<Float>(0, 0, 0)
        case .rain: return SIMD3<Float>(0, 5, 0)
        case .fireworks: return SIMD3<Float>(0, -3, 0)
        case .tornado: return SIMD3<Float>(0, 0, 0)
        }
    }

    private func updateTime() {
        if !isPaused {
            time += 1.0/60.0
            frameCount += 1
        }
    }
}

// Use the structs from the Metal header
import UltraviolenceExampleShaders

// Compute element for updating particles
private struct ParticleUpdateCompute: Element {
    let particleBuffer: MTLBuffer
    let emitterBuffer: MTLBuffer
    let particleCount: Int
    let time: Float
    let gravity: SIMD3<Float>
    let emitterType: ParticleEffectsDemoView.EmitterType
    let emissionRate: Float

    init(particleBuffer: MTLBuffer, emitterBuffer: MTLBuffer, particleCount: Int, time: Float, gravity: SIMD3<Float>, emitterType: ParticleEffectsDemoView.EmitterType, emissionRate: Float) {
        self.particleBuffer = particleBuffer
        self.emitterBuffer = emitterBuffer
        self.particleCount = particleCount
        self.time = time
        self.gravity = gravity
        self.emitterType = emitterType
        self.emissionRate = emissionRate

        // Update emitter parameters before compute pass
        let emitterParams = ParticleEmitterParams(
            position: getEmitterPosition(for: emitterType),
            emitterType: Int32(ParticleEffectsDemoView.EmitterType.allCases.firstIndex(of: emitterType) ?? 0),
            emissionRate: emissionRate,
            time: time
        )
        memcpy(emitterBuffer.contents(), [emitterParams], MemoryLayout<ParticleEmitterParams>.stride)
    }

    var body: some Element {
        get throws {
            let device = MTLCreateSystemDefaultDevice()!
            let bundle = Bundle.ultraviolenceExampleShaders()!
            let library = try! device.makeDefaultLibrary(bundle: bundle)
            let updateFunction = library.makeFunction(name: "updateParticles")!

            let uniforms = ParticleUniforms(
                viewMatrix: .identity,
                projectionMatrix: .identity,
                time: time,
                _padding1: (0, 0, 0),
                gravity: gravity,
                baseSize: 1.0
            )

            try ComputePipeline(computeKernel: ComputeKernel(updateFunction)) {
                try ComputeDispatch(
                    threadsPerGrid: MTLSize(width: particleCount, height: 1, depth: 1),
                    threadsPerThreadgroup: MTLSize(width: 64, height: 1, depth: 1)
                )
                .parameter("particles", buffer: particleBuffer)
                .parameter("uniforms", value: uniforms)
                .parameter("emitter", buffer: emitterBuffer)
                .parameter("particleCount", value: UInt32(particleCount))
            }
        }
    }

    private func getEmitterPosition(for type: ParticleEffectsDemoView.EmitterType) -> SIMD3<Float> {
        switch type {
        case .fountain: return SIMD3<Float>(0, -2, 0)
        case .explosion: return SIMD3<Float>(0, 0, 0)
        case .rain: return SIMD3<Float>(0, 5, 0)
        case .fireworks: return SIMD3<Float>(0, -3, 0)
        case .tornado: return SIMD3<Float>(0, 0, 0)
        }
    }

}

// Render pipeline for particles
private struct ParticleRenderPipeline: Element {
    let particleBuffer: MTLBuffer
    let particleCount: Int
    let viewMatrix: simd_float4x4
    let projectionMatrix: simd_float4x4
    let time: Float
    let gravity: SIMD3<Float>
    let baseSize: Float

    private var vertexDescriptor: MTLVertexDescriptor {
        MTLVertexDescriptor()  // Using buffer directly, no vertex descriptor needed
    }

    var body: some Element {
        get throws {
            let device = MTLCreateSystemDefaultDevice()!
            let bundle = Bundle.ultraviolenceExampleShaders()!
            let library = try! device.makeDefaultLibrary(bundle: bundle)

            let vertexFunction = library.makeFunction(name: "particleEffectsVertex")!
            let fragmentFunction = library.makeFunction(name: "particleEffectsFragment")!

            try RenderPipeline(
                vertexShader: VertexShader(vertexFunction),
                fragmentShader: FragmentShader(fragmentFunction)
            ) {
                Draw { encoder in
                    let uniforms = ParticleUniforms(
                        viewMatrix: viewMatrix,
                        projectionMatrix: projectionMatrix,
                        time: time,
                        _padding1: (0, 0, 0),
                        gravity: gravity,
                        baseSize: baseSize
                    )
                    encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
                    encoder.setVertexBytes([uniforms], length: MemoryLayout<ParticleUniforms>.stride, index: 1)
                    encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
                }
            }
            .vertexDescriptor(vertexDescriptor)
            .renderPipelineDescriptorModifier { renderPipelineDescriptor in
                // Simple additive blending for glow effect (optional)
                renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
                renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
                renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
            }
        }
    }
}
