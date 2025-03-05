#import <metal_stdlib>
#import "include/UltraviolenceExampleShaders.h"

using namespace metal;

namespace FlatShader {
    struct VertexIn {
        float3 position [[attribute(0)]];
        float3 normal [[attribute(1)]];
        float2 textureCoordinate [[attribute(2)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    [[vertex]] VertexOut vertex_main(
        uint instance_id [[instance_id]],
        const VertexIn in [[stage_in]],
        constant float4x4 &projectionMatrix [[buffer(1)]],
        constant float4x4 &viewMatrix [[buffer(2)]],
        constant float4x4 &modelMatrix [[buffer(3)]]
    ) {
        VertexOut out;
        float4 objectSpace = float4(in.position, 1.0);
        float4x4 mvp = projectionMatrix * viewMatrix * modelMatrix;
        out.position = mvp * objectSpace;
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant Texture2DSpecifierArgumentBuffer &texture [[buffer(0)]]
    ) {
        // Sample the texture

        if (texture.source == kColorSourceColor) {
            return texture.color;
        }
        else if (texture.source == kColorSourceTexture) {
            float4 color = texture.texture.sample(texture.sampler, in.textureCoordinate);
            return color;
        }
        else {
            discard_fragment();
            return float4(0.0, 0.0, 0.0, 0.0);
        }
    }
}
