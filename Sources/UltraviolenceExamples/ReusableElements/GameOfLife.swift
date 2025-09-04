import Foundation
import Metal
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

/// A Game of Life simulation element that runs entirely on the GPU
public struct GameOfLife: Element {
    @UVEnvironment(\.device)
    var device

    @UVState
    private var textureA: MTLTexture?

    @UVState
    private var textureB: MTLTexture?

    @UVState
    private var currentTextureIsA = true

    @UVState
    private var initialized = false

    @UVState
    private var frameCount = 0

    @UVState
    private var vertexBuffer: MTLBuffer?

    let gridSize: (width: Int, height: Int)
    let updateInterval: Int // Update every N frames
    let isRunning: Bool
    let pattern: InitialPattern

    @UVState
    private var lastPattern: InitialPattern = .clear

    public enum InitialPattern: String, CaseIterable {
        case glider = "Glider"
        case random = "Random"
        case clear = "Clear"
        case blinker = "Blinker"
        case toad = "Toad"
    }

    public init(
        gridSize: (width: Int, height: Int) = (256, 256),
        updateInterval: Int = 2,
        isRunning: Bool = true,
        pattern: InitialPattern = .random
    ) {
        self.gridSize = gridSize
        self.updateInterval = updateInterval
        self.isRunning = isRunning
        self.pattern = pattern
    }

    public var body: some Element {
        get throws {
            // Initialize textures lazily
            setupTexturesIfNeeded()

            // Initialize grid if needed
            if pattern != lastPattern || !initialized {
                initializeGridIfNeeded()
                lastPattern = pattern
                initialized = true
            }

            let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
            let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "GameOfLifeShader")

            // Create vertex descriptor for interleaved data
            let vertexDescriptor = MTLVertexDescriptor()

            // Position attribute (float2 at attribute 0)
            vertexDescriptor.attributes[0].format = .float2
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0

            // Texture coordinates attribute (float2 at attribute 1)
            vertexDescriptor.attributes[1].format = .float2
            vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
            vertexDescriptor.attributes[1].bufferIndex = 0

            // Layout for buffer 0 (interleaved data)
            vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
            vertexDescriptor.layouts[0].stepRate = 1
            vertexDescriptor.layouts[0].stepFunction = .perVertex

            return try Group {
                // Update simulation if running
                if isRunning && frameCount % updateInterval == 0 {
                    try ComputePass {
                        try ComputePipeline(computeKernel: try shaderLibrary.updateGrid) {
                            try ComputeDispatch(
                                threadsPerGrid: MTLSize(width: gridSize.width, height: gridSize.height, depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1)
                            )
                            .parameter("currentState", texture: currentTexture)
                            .parameter("nextState", texture: nextTexture)
                        }
                    }
                    .onCommandBufferCompleted { _ in
                        // Swap textures after compute pass completes
                        currentTextureIsA.toggle()
                    }
                }

                // Display the current state
                try RenderPass {
                    try RenderPipeline(
                        vertexShader: try shaderLibrary.displayVertex,
                        fragmentShader: try shaderLibrary.displayFragment
                    ) {
                        Draw { encoder in
                            // Create sampler
                            let samplerDescriptor = MTLSamplerDescriptor()
                            samplerDescriptor.minFilter = .nearest
                            samplerDescriptor.magFilter = .nearest
                            let sampler = device?.makeSamplerState(descriptor: samplerDescriptor)

                            // Set vertex buffer
                            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

                            encoder.setFragmentTexture(currentTexture, index: 0)
                            encoder.setFragmentSamplerState(sampler, index: 0)

                            // Draw fullscreen triangle
                            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                        }
                    }
                    .vertexDescriptor(vertexDescriptor)
                }
            }
            .onCommandBufferCompleted { _ in
                frameCount += 1
            }
        }
    }

    private var currentTexture: MTLTexture {
        currentTextureIsA ? textureA.orFatalError() : textureB.orFatalError()
    }

    private var nextTexture: MTLTexture {
        currentTextureIsA ? textureB.orFatalError() : textureA.orFatalError()
    }

    private func setupTexturesIfNeeded() {
        guard textureA == nil || textureB == nil,
              let device = self.device else {
            return
        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: gridSize.width,
            height: gridSize.height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private

        textureA = device.makeTexture(descriptor: textureDescriptor)
        textureB = device.makeTexture(descriptor: textureDescriptor)

        // Setup vertex buffer for fullscreen triangle
        if vertexBuffer == nil {
            // Create a fullscreen triangle with position and texture coordinates
            // Each vertex has: float2 position + float2 texCoords = 4 floats
            let vertices: [Float] = [
                // position     texCoords
                -1.0, -3.0, 0.0, 2.0,  // bottom left (off-screen)
                -1.0, 1.0, 0.0, 0.0,  // top left
                3.0, 1.0, 2.0, 0.0   // top right (off-screen)
            ]
            vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: .storageModeShared)
        }
    }

    private func initializeGridIfNeeded() {
        guard let device = self.device,
              let textureA = self.textureA,
              let textureB = self.textureB else {
            return
        }

        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        guard let shaderLibrary = try? ShaderLibrary(bundle: shaderBundle, namespace: "GameOfLifeShader") else {
            return
        }

        let initKernel: ComputeKernel
        var parameters: [(String, Any)] = []

        do {
            switch pattern {
            case .glider:
                initKernel = try shaderLibrary.initializeGlider
                // Place glider at center
                let offset = SIMD2<UInt32>(UInt32(gridSize.width / 2), UInt32(gridSize.height / 2))
                parameters.append(("offset", offset))
            case .random:
                initKernel = try shaderLibrary.initializeRandom
                let density: Float = 0.3
                let seed = UInt32.random(in: 0..<UInt32.max)
                parameters.append(("density", density))
                parameters.append(("seed", seed))
            case .clear:
                initKernel = try shaderLibrary.clearGrid
            case .blinker:
                initKernel = try shaderLibrary.clearGrid // Start with clear then add pattern manually
            case .toad:
                initKernel = try shaderLibrary.clearGrid // Start with clear then add pattern manually
            }
        } catch {
            return
        }

        // Initialize both textures
        for texture in [textureA, textureB] {
            let commandQueue = device.makeCommandQueue().orFatalError()
            let commandBuffer = commandQueue.makeCommandBuffer().orFatalError()
            let computeEncoder = commandBuffer.makeComputeCommandEncoder().orFatalError()

            guard let pipelineState = try? device.makeComputePipelineState(function: initKernel.function) else { continue }
            computeEncoder.setComputePipelineState(pipelineState)
            computeEncoder.setTexture(texture, index: 0)

            // Set parameters based on pattern
            for (index, (_, value)) in parameters.enumerated() {
                if let uint2Value = value as? SIMD2<UInt32> {
                    computeEncoder.setBytes([uint2Value], length: MemoryLayout<SIMD2<UInt32>>.size, index: index)
                } else if let floatValue = value as? Float {
                    computeEncoder.setBytes([floatValue], length: MemoryLayout<Float>.size, index: index)
                } else if let uintValue = value as? UInt32 {
                    computeEncoder.setBytes([uintValue], length: MemoryLayout<UInt32>.size, index: index)
                }
            }

            let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
            let threadgroups = MTLSize(
                width: (gridSize.width + 15) / 16,
                height: (gridSize.height + 15) / 16,
                depth: 1
            )
            computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)

            computeEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
