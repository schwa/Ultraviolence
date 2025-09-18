#import <metal_stdlib>
#import "include/UltraviolenceExampleShaders.h"
#import "include/WireframeShader.h"

using namespace metal;

namespace WireframeShader {

    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal [[attribute(1)]];
        float2 textureCoordinate [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]],
        constant WireframeUniforms &uniforms [[buffer(1)]]
    ) {
        VertexOut out;
        float4 objectSpace = float4(in.position, 1.0);
        out.position = uniforms.modelViewProjectionMatrix * objectSpace;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant WireframeUniforms &uniforms [[buffer(0)]]
    ) {
        return uniforms.wireframeColor;
    }

} // namespace WireframeShader