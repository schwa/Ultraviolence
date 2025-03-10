#include <metal_stdlib>
using namespace metal;

using namespace metal;

// sRGB to Linear conversion
float3 srgbToLinear(float3 c) {
  return c;
  //    return select(c / 12.92, pow((c + 0.055) / 1.055, 2.4), c > 0.04045);
}

// Linear to sRGB conversion
float3 linearToSrgb(float3 c) {
  return c;
  //    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c >
  //    0.0031308);
}

kernel void applyLUT(texture2d<float, access::read> inputTexture [[texture(0)]],
                     texture2d<float, access::write> outputTexture
                     [[texture(1)]],
                     texture3d<float, access::sample> lutTexture [[texture(2)]],
                     constant float &blend [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
  if (gid.x >= inputTexture.get_width() || gid.y >= inputTexture.get_height())
    return;

  constexpr sampler lutSampler(coord::normalized, address::clamp_to_edge,
                               filter::linear);
  float4 color = inputTexture.read(gid);
  //    color.rgb = srgbToLinear(color.rgb); // Ensure input is in linear space
  float4 lutColor = lutTexture.sample(lutSampler, color.rgb);
  //    lutColor.rgb = srgbToLinear(lutColor.rgb);
  float4 outputColor = mix(color, lutColor, blend);
  //    outputColor.rgb = linearToSrgb(outputColor.rgb);
  outputTexture.write(outputColor, gid);
}
