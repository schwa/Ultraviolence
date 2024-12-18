import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

// swiftlint:disable force_try

struct ContentView: View {
    @SwiftUI.State
    var size: CGSize = .zero

    var body: some View {
        RenderView(MyRenderPass(size: size))
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
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
    let model: simd_float4x4 = .identity
    var view: simd_float4x4 {
        float4x4(translation: cameraPosition).inverse
    }
    let cameraPosition: SIMD3<Float> = [1, 2, 6]

    init(size: CGSize) {
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
                constant float4x4 &projection [[buffer(1)]],
                constant float4x4 &model [[buffer(2)]],
                constant float4x4 &view [[buffer(3)]]
            ) {
                VertexOut out;

                // Transform position to clip space
                float4 objectSpace = float4(in.position, 1.0);
                out.position = projection * view * model * objectSpace;

                // Transform position to world space for rim lighting
                out.worldPosition = (model * objectSpace).xyz;

                // Transform normal to world space and invert it
                float3x3 normalMatrix = float3x3(model[0].xyz, model[1].xyz, model[2].xyz);
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
        vertexShader = try! VertexShader(source: source)
        fragmentShader = try! FragmentShader(source: source)
        self.size = size

        let device = try! MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let url = try! Bundle.main.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        // swiftlint:disable:next force_cast
        let mdlMesh = mdlAsset.object(at: 0) as! MDLMesh
        mesh = try! MTKMesh(mesh: mdlMesh, device: device)
    }

    var body: some RenderPass {
        Render {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.draw(mesh)
                }
                .parameter("color", Color.green)
                .parameter("projection", PerspectiveProjection().projectionMatrix(for: [Float(size.width), Float(size.height)]))
                .parameter("model", model)
                .parameter("view", view)
                .parameter("lightDirection", SIMD3<Float>([-1, -2, -1]))
                .parameter("cameraPosition", cameraPosition)
            }
            .environment(\.vertexDescriptor, MTLVertexDescriptor(mesh.vertexDescriptor))
        }
    }
}
