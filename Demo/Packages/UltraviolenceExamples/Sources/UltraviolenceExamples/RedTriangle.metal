#include <metal_stdlib>
using namespace metal;

namespace RedTriangle {
struct VertexIn {
  float2 position [[attribute(0)]];
};

struct VertexOut {
  float4 position [[position]];
};

[[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
  VertexOut out;
  out.position = float4(in.position, 0.0, 1.0);
  return out;
}

[[fragment]] float4 fragment_main(VertexOut in [[stage_in]],
                                  constant float4 &color [[buffer(0)]]) {
  return color;
}
} // namespace RedTriangle
