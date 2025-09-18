import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import GeometryLite3D
import simd
import Metal
import UltraviolenceExampleShaders

public struct PointCloudDemoView: View {
    @State private var projection: any ProjectionProtocol = PerspectiveProjection()
    @State private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 5])
    @State private var pointSize: Float = 5.0
    @State private var pointCount: Int = 25000
    @State private var drawableSize: CGSize = .zero

    // Torus parameters
    @State private var majorRadius: Float = 2.0
    @State private var minorRadius: Float = 0.8

    // Point cloud data
    @State private var pointBuffer: MTLBuffer?
    @State private var vertexCount: Int = 0

    public init() {}

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView { context, drawableSize in
                if let pointBuffer {
                    try RenderPass {
                        PointCloudRenderPipeline(
                            pointBuffer: pointBuffer,
                            vertexCount: vertexCount,
                            viewMatrix: cameraMatrix.inverse,
                            projectionMatrix: projection.projectionMatrix(for: drawableSize),
                            pointSize: pointSize
                        )
                        .depthCompare(function: .less, enabled: true)
                    }
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .onDrawableSizeChange {
                drawableSize = $0
            }
            .onAppear {
                generatePointCloud()
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                Text("Point Cloud Demo")
                    .font(.headline)

                Label("Points: \(pointCount)", systemImage: "circle.grid.3x3.fill")
                Slider(value: Binding(get: { Double(pointCount) }, set: { pointCount = Int($0) }), in: 1000...200000, step: 1000)
                    .onChange(of: pointCount) { _, _ in
                        generatePointCloud()
                    }

                Label("Point Size: \(pointSize, specifier: "%.1f")", systemImage: "circle.fill")
                Slider(value: $pointSize, in: 1...30)

                Label("Major Radius: \(majorRadius, specifier: "%.1f")", systemImage: "circle")
                Slider(value: $majorRadius, in: 1...3)
                    .onChange(of: majorRadius) { _, _ in
                        generatePointCloud()
                    }

                Label("Minor Radius: \(minorRadius, specifier: "%.1f")", systemImage: "circle")
                Slider(value: $minorRadius, in: 0.2...1.5)
                    .onChange(of: minorRadius) { _, _ in
                        generatePointCloud()
                    }

                Button("Regenerate") {
                    generatePointCloud()
                }
            }
            .frame(width: 300)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }

    private func generatePointCloud() {
        let device = MTLCreateSystemDefaultDevice()!

        // Generate points on/in a torus
        var points: [PointVertex] = []
        points.reserveCapacity(pointCount)

        for _ in 0..<pointCount {
            // Random parameters for torus
            let u = Float.random(in: 0..<(2 * .pi))
            let v = Float.random(in: 0..<(2 * .pi))
            let r = minorRadius * sqrt(Float.random(in: 0...1)) // Random radius within minor radius for volume filling

            // Torus parametric equations with volume
            let x = (majorRadius + r * cos(v)) * cos(u)
            let y = (majorRadius + r * cos(v)) * sin(u)
            let z = r * sin(v)

            // Rainbow color based on position
            let hue = (u / (2 * .pi) + v / (2 * .pi)) / 2.0
            let color = hsvToRgb(h: hue, s: 0.8, v: 1.0)

            points.append(PointVertex(position: SIMD3<Float>(x, y, z), color: color))
        }

        // Create Metal buffer
        let bufferSize = points.count * MemoryLayout<PointVertex>.stride
        pointBuffer = device.makeBuffer(bytes: points, length: bufferSize, options: [])
        pointBuffer?.label = "Point Cloud Buffer"
        vertexCount = points.count
    }

    private func hsvToRgb(h: Float, s: Float, v: Float) -> SIMD3<Float> {
        let c = v * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c

        let rgb: SIMD3<Float>
        let h6 = h * 6

        if h6 < 1 {
            rgb = SIMD3(c, x, 0)
        } else if h6 < 2 {
            rgb = SIMD3(x, c, 0)
        } else if h6 < 3 {
            rgb = SIMD3(0, c, x)
        } else if h6 < 4 {
            rgb = SIMD3(0, x, c)
        } else if h6 < 5 {
            rgb = SIMD3(x, 0, c)
        } else {
            rgb = SIMD3(c, 0, x)
        }

        return rgb + SIMD3(m, m, m)
    }
}

// Point vertex structure matching Metal shader
private struct PointVertex {
    let position: SIMD3<Float>
    let color: SIMD3<Float>
}

private struct Uniforms {
    let viewMatrix: simd_float4x4
    let projectionMatrix: simd_float4x4
    let pointSize: Float
}

// Simplified point cloud rendering using RenderPipeline
private struct PointCloudRenderPipeline: Element {
    let pointBuffer: MTLBuffer
    let vertexCount: Int
    let viewMatrix: simd_float4x4
    let projectionMatrix: simd_float4x4
    let pointSize: Float

    private var vertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<PointVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        return vertexDescriptor
    }

    var body: some Element {
        get throws {
            let device = MTLCreateSystemDefaultDevice()!
            let bundle = Bundle.ultraviolenceExampleShaders()!
            let library = try! device.makeDefaultLibrary(bundle: bundle)

            let vertexFunction = library.makeFunction(name: "pointCloudVertex")!
            let fragmentFunction = library.makeFunction(name: "pointCloudFragment")!

            try RenderPipeline(
                vertexShader: VertexShader(vertexFunction),
                fragmentShader: FragmentShader(fragmentFunction)
            ) {
                Draw { encoder in
                    let uniforms = Uniforms(
                        viewMatrix: viewMatrix,
                        projectionMatrix: projectionMatrix,
                        pointSize: pointSize
                    )
                    encoder.setVertexBuffer(pointBuffer, offset: 0, index: 0)
                    encoder.setVertexBytes([uniforms], length: MemoryLayout<Uniforms>.stride, index: 1)
                    encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
                }
            }
            .vertexDescriptor(vertexDescriptor)
        }
    }
}
