import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

// swiftlint:disable force_try

struct ContentView: View {
    @SwiftUI.State
    var size: CGSize = .zero

    @SwiftUI.State
    var angle: SwiftUI.Angle = .zero

    var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))

        RenderView(try! MyRenderPass(size: size, modelMatrix: modelMatrix))
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .overlay(alignment: .bottom) {
                VStack {
                    Slider(value: $angle.radians, in: 0...(.pi * 2))
                }
                .controlSize(.small)
                .frame(maxWidth: 320)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
    }
}

#Preview {
    ContentView()
}

struct MyRenderPass: RenderPass {
    @Ultraviolence.State var vertexShader: VertexShader
    @Ultraviolence.State var fragmentShader: FragmentShader
    @Ultraviolence.State var mesh: MTKMesh
    @Ultraviolence.State var size: CGSize

    let modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4 {
        float4x4(translation: cameraPosition).inverse
    }
    let cameraPosition: SIMD3<Float> = [0, 2, 6]

    init(size: CGSize, modelMatrix: simd_float4x4) throws {
        // TODO: Currently everything will be recompiled.
        print("RECOMPILE")
        let source = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexIn {
                float3 position [[attribute(0)]];
                float3 normal [[attribute(1)]];
                float2 textureCoordinate [[attribute(2)]];
            };

            struct VertexOut {
                float4 position [[position]];
                float3 normal;
                float3 worldNormal;
                float3 worldPosition;
            };

            [[vertex]] VertexOut vertex_main(
                const VertexIn in [[stage_in]],
                constant float4x4 &projectionMatrix [[buffer(1)]],
                constant float4x4 &modelMatrix [[buffer(2)]],
                constant float4x4 &viewMatrix [[buffer(3)]]
            ) {
                VertexOut out;

                // Transform position to clip space
                float4 objectSpace = float4(in.position, 1.0);
                out.position = projectionMatrix * viewMatrix * modelMatrix * objectSpace;

                // Transform position to world space for rim lighting
                out.worldPosition = (modelMatrix * objectSpace).xyz;

                // Transform normal to world space and invert it
                float3x3 normalMatrix = float3x3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz);
                out.worldNormal = normalize(-(normalMatrix * in.normal));

                return out;
            }

            [[fragment]] float4 fragment_main(
                VertexOut in [[stage_in]],
                constant float4 &color [[buffer(0)]],
                constant float3 &lightDirection [[buffer(1)]],
                constant float3 &cameraPosition [[buffer(2)]]
            ) {
                // Normalize light and view directions
                float3 lightDir = normalize(lightDirection);
                float3 viewDir = normalize(cameraPosition - in.worldPosition);

                // Lambertian shading calculation
                float lambertian = max(dot(in.worldNormal, lightDir), 0.0);

                // Rim lighting calculation
                float rim = pow(1.0 - dot(in.worldNormal, viewDir), 2.0);
                float rimIntensity = 0.25 * rim;  // Adjust the intensity of the rim light as needed

                // Combine Lambertian shading and rim lighting
                float combinedIntensity = lambertian * rimIntensity;

                // Apply combined intensity to color
                float4 shadedColor = float4(color.xyz * combinedIntensity, 1.0);
                return shadedColor;
            }
        """
        vertexShader = try VertexShader(source: source)
        fragmentShader = try FragmentShader(source: source)
        self.size = size

        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let url = try Bundle.main.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        // swiftlint:disable:next force_cast
        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orThrow(.resourceCreationFailure)
        mesh = try MTKMesh(mesh: mdlMesh, device: device)

        self.modelMatrix = modelMatrix
    }

    var body: some RenderPass {
        Render {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.draw(mesh)
                }
                // TODO: Doesn't seperate the parameters for the two shader types.
                .parameter("color", Color.green)
                .parameter("projectionMatrix", PerspectiveProjection().projectionMatrix(for: [Float(size.width), Float(size.height)]))
                .parameter("modelMatrix", modelMatrix)
                .parameter("viewMatrix", viewMatrix)
                .parameter("lightDirection", SIMD3<Float>([-1, -2, -1]))
                .parameter("cameraPosition", cameraPosition)
            }
            .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
            .depthCompare(function: .less, enabled: true)
        }
    }
}
