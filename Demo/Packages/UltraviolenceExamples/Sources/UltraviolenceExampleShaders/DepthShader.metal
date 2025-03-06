#import "include/UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace DepthShader {
struct VertexIn {
  float3 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
};

[[vertex]] VertexOut vertex_main(uint instance_id [[instance_id]],
                                 const VertexIn in [[stage_in]],
                                 constant Transforms &transforms
                                 [[buffer(1)]]) {
  VertexOut out;
  float4 objectSpace = float4(in.position, 1.0);
  float4x4 mvp = transforms.projectionMatrix * transforms.viewMatrix *
                 transforms.modelMatrix;
  out.position = mvp * objectSpace;
  return out;
}

[[fragment]] float4 fragment_main(VertexOut in [[stage_in]]) {
  float depth = in.position.z;             // Depth value
  return float4(depth, depth, depth, 1.0); // Encode as grayscale
}
} // namespace DepthShader
