#include <metal_stdlib>
#include <metal_uniform>

using namespace metal;

namespace LambertianShader {
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
        float3 color;
    };

    VertexOut lambertian(
        float3 position,
        float3 normal,
        constant float4x4 &projectionMatrix,
        float4x4 modelMatrix,
        constant float4x4 &viewMatrix,
        float3 color
    ) {
        VertexOut out;
        float4 objectSpace = float4(position, 1.0);
        // TODO: we should, of course, pre-calculate the matrices and pass them
        // in.
        out.position = projectionMatrix * viewMatrix * modelMatrix * objectSpace;
        out.worldPosition = (modelMatrix * objectSpace).xyz;
        float3x3 normalMatrix = float3x3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz);
        out.worldNormal = normalize(-(normalMatrix * normal));
        out.color = color;
        return out;
    }

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]],
        constant float4x4 &projectionMatrix [[buffer(1)]],
        constant float4x4 &modelMatrix [[buffer(2)]],
        constant float4x4 &viewMatrix [[buffer(3)]],
        constant float3 &color [[buffer(4)]]
    ) {
        return lambertian(in.position, in.normal, projectionMatrix, modelMatrix, viewMatrix, color);
    }

    [[vertex]] VertexOut vertex_instanced(
        const VertexIn in [[stage_in]],
        constant float4x4 &projectionMatrix [[buffer(1)]],
        constant float4x4 &viewMatrix [[buffer(3)]],
        uint instance_id [[instance_id]],
        constant float4x4 *modelMatrices [[buffer(2)]],
        constant float3 *colors [[buffer(4)]]
    ) {
        const float4x4 modelMatrix = modelMatrices[instance_id];
        const float3 color = colors[instance_id];
        return lambertian(in.position, in.normal, projectionMatrix, modelMatrix, viewMatrix, color);
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
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
        float rimIntensity = 0.25 * rim; // Adjust the intensity of the rim light as needed

        // Combine Lambertian shading and rim lighting
        float combinedIntensity = lambertian * rimIntensity;

        // Apply combined intensity to color
        float4 shadedColor = float4((in.color * combinedIntensity).xyz, 1.0);
        return shadedColor;
    }

} // namespace LambertianShader
