#import "include/UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace SkyboxShader {
    struct VertexIn {
        float3 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float3 textureCoordinate;
    };

    [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]], constant Transforms &transforms [[buffer(4)]]) {
        VertexOut out;
        float4 objectSpace = float4(in.position, 1.0);
        float4x4 mvp = transforms.projectionMatrix * transforms.viewMatrix * transforms.modelMatrix;
        out.position = mvp * objectSpace;
        out.textureCoordinate = float3(-in.position.x, in.position.y, in.position.z);
        ;
        return out;
    }

    [[fragment]] float4
    fragment_main(VertexOut in [[stage_in]], texturecube<float, access::sample> texture [[texture(0)]]) {
        constexpr sampler s;
        return texture.sample(s, in.textureCoordinate);
    }
} // namespace SkyboxShader
