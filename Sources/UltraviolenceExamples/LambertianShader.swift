import CoreGraphics
import simd
import Ultraviolence
internal import UltraviolenceSupport

public struct LambertianShader <Content>: RenderPass where Content: RenderPass {
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
        float4 shadedColor = float4((color * combinedIntensity).xyz, 1.0);
        return shadedColor;
    }
    """

    var color: SIMD4<Float>
    var size: CGSize
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var cameraPosition: SIMD3<Float>
    var content: Content
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader

    public init(color: SIMD4<Float>, size: CGSize, modelMatrix: simd_float4x4, viewMatrix: simd_float4x4, cameraPosition: SIMD3<Float>, content: () -> Content) throws {
        self.color = color
        self.size = size
        self.modelMatrix = modelMatrix
        self.viewMatrix = viewMatrix
        self.cameraPosition = cameraPosition
        self.content = content()
        vertexShader = try VertexShader(source: source)
        fragmentShader = try FragmentShader(source: source)
    }

    public var body: some RenderPass {
        RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
            content
                .parameter("color", color)
                .parameter("projectionMatrix", PerspectiveProjection().projectionMatrix(for: [Float(size.width), Float(size.height)]))
                .parameter("modelMatrix", modelMatrix)
                .parameter("viewMatrix", viewMatrix)
                .parameter("lightDirection", SIMD3<Float>([-1, -2, -1]))
                .parameter("cameraPosition", cameraPosition)
        }
    }
}
