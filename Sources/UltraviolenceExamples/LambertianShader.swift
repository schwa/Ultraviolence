import CoreGraphics
import simd
import Ultraviolence
internal import UltraviolenceSupport

public struct LambertianShader: RenderPass {
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
        float4 shadedColor = float4(color * combinedIntensity).xyz, 1.0);
        return shadedColor;
    }
    """

    var geometry: [Geometry]
    var color: SIMD4<Float>
    var size: CGSize
    var model: simd_float4x4
    var view: simd_float4x4
    var cameraPosition: SIMD3<Float>

    public init(geometry: [Geometry], color: SIMD4<Float>, size: CGSize, model: simd_float4x4, view: simd_float4x4, cameraPosition: SIMD3<Float>) {
        self.geometry = geometry
        self.color = color
        self.size = size
        self.model = model
        self.view = view
        self.cameraPosition = cameraPosition
    }

    public var body: some RenderPass {
        get throws {
            try Draw(geometry) {
                try VertexShader("vertex_main", source: source)
                try FragmentShader("fragment_main", source: source)
            }
            .argument(type: .vertex, name: "projection", value: PerspectiveProjection().projectionMatrix(for: [Float(size.width), Float(size.height)]))
            .argument(type: .vertex, name: "model", value: model)
            .argument(type: .vertex, name: "view", value: view)
            .argument(type: .fragment, name: "color", value: color)
            .argument(type: .fragment, name: "lightDirection", value: SIMD3<Float>([-1, -2, -1]))
            .argument(type: .fragment, name: "cameraPosition", value: cameraPosition)
        }
    }
}
