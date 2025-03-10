#include <metal_stdlib>
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

[[fragment]] float4 fragment_main(VertexOut in [[stage_in]],
                                  constant int &input [[buffer(0)]],
                                  constant int &slice [[buffer(1)]],

                                  texture2d<float> texture2d [[texture(2)]],
                                  texturecube<float> textureCube
                                  [[texture(3)]]) {
  constexpr sampler s;
  if (input == 0) {
    return texture2d.sample(s, in.textureCoordinate);
  } else if (input == 1) {
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

    auto color = textureCube.sample(s, direction);
    color.a = 1.0;
    return color;
  }
}
} // namespace TextureBillboard
