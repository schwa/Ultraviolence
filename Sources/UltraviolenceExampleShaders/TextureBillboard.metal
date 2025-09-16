#import "include/UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace TextureBillboard {

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 textureCoordinate [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant Texture2DSpecifierArgumentBuffer &specifier [[buffer(0)]],
        constant int &slice [[buffer(1)]]
    ) {
        // TODO: Move this into helper function - SHARED WITH TEXTUREBILLBOARD & FLATSHADER & BLINN PHONG
        if (specifier.source == kColorSourceColor) {
            return float4(specifier.color, 1);
        } else if (specifier.source == kColorSourceTextureCube) {
            float2 uv = in.textureCoordinate;
            float3 direction;
            switch (slice) {
            case 0:
                direction = float3(1.0, uv.y, -uv.x);
                break; // +X
            case 1:
                direction = float3(-1.0, uv.y, uv.x);
                break; // -X
            case 2:
                direction = float3(uv.x, 1.0, -uv.y);
                break; // +Y
            case 3:
                direction = float3(uv.x, -1.0, uv.y);
                break; // -Y
            case 4:
                direction = float3(uv.x, uv.y, 1.0);
                break; // +Z
            case 5:
                direction = float3(-uv.x, uv.y, -1.0);
                break; // -Z
            }
            auto color = specifier.textureCube.sample(specifier.sampler, direction);
            color.a = 1.0;
            return color;
        } else if (specifier.source == kColorSourceTexture2D) {
            return specifier.texture2D.sample(specifier.sampler, in.textureCoordinate);
        } else if (specifier.source == kColorSourceDepth2D) {
            float depth = specifier.depth2D.sample(specifier.sampler, in.textureCoordinate);
            float d = pow(depth, 50.0);
            return float4(d, d, d, 1);
        } else {
            discard_fragment();
            return float4(0.0, 0.0, 0.0, 0.0);
        }
    }

} // namespace TextureBillboard
