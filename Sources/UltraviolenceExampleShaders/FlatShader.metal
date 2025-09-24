#import <metal_stdlib>

#import "ColorSource.h"
#import "UltraviolenceExampleShaders.h"

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
        uint instance_id [[instance_id]], const VertexIn in [[stage_in]], constant Transforms &transforms [[buffer(1)]]
    ) {
        VertexOut out;
        float4 objectSpace = float4(in.position, 1.0);
        float4x4 mvp = transforms.projectionMatrix * transforms.viewMatrix * transforms.modelMatrix;
        out.position = mvp * objectSpace;
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4
    fragment_main(VertexOut in [[stage_in]], constant ColorSourceArgumentBuffer &specifier [[buffer(0)]]) {
        return specifier.resolve(in.textureCoordinate);
    }

} // namespace FlatShader
