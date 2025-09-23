#import <metal_stdlib>
#import "UltraviolenceExampleShaders.h"

using namespace metal;

namespace DebugShader {

    typedef DebugShadersMode DebugMode;

    typedef DebugShadersUniforms Uniforms;
    typedef DebugShadersAmplifiedUniforms AmplifiedUniforms;

        struct VertexIn {
            float3 position [[attribute(0)]];
            float3 normal [[attribute(1)]];
            float2 texCoord [[attribute(2)]];
            float3 tangent [[attribute(3)]];
            float3 bitangent [[attribute(4)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float3 worldPosition;
            float3 worldNormal;
            float2 texCoord;
            float3 worldTangent;
            float3 worldBitangent;
            float3 localPosition;
            uint amplificationID [[flat]];
            uint instanceID [[flat]];
        };
    
        vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                     constant Uniforms& uniforms [[buffer(1)]],
                                     constant AmplifiedUniforms* amplifiedUniforms [[buffer(2)]],
                                     uint amplification_id [[amplification_id]],
                                     uint instance_id [[instance_id]]) {
            VertexOut out;

            // Transform position to world space
            float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
            out.worldPosition = worldPosition.xyz;
            out.localPosition = in.position;

            // Transform position to clip space
            out.position = amplifiedUniforms[amplification_id].viewProjectionMatrix * worldPosition;

            // Transform normal, tangent, and bitangent to world space
            out.worldNormal = normalize(uniforms.normalMatrix * in.normal);
            out.worldTangent = normalize(uniforms.normalMatrix * in.tangent);
            out.worldBitangent = normalize(uniforms.normalMatrix * in.bitangent);

            // Pass through texture coordinates
            out.texCoord = in.texCoord;

            // Pass through IDs for visualization
            out.amplificationID = amplification_id;
            out.instanceID = instance_id;

            return out;
        }

        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                      constant Uniforms& uniforms [[buffer(0)]],
                                      uint primitive_id [[primitive_id]],
                                      uint thread_index_in_quadgroup [[thread_index_in_quadgroup]],
                                      uint thread_index_in_simdgroup [[thread_index_in_simdgroup]],
                                      uint threads_per_simdgroup [[threads_per_simdgroup]],
                                      float3 barycentric_coord [[barycentric_coord]],
                                      bool front_facing [[front_facing]],
                                      uint sample_id [[sample_id]],
                                      float2 point_coord [[point_coord]]
                                      ) {

            float3 color;

            switch (uniforms.debugMode) {
                case kDebugShadersModeNormal:
                    // Visualize normals: map from [-1,1] to [0,1] color range
                    color = (normalize(in.worldNormal) + 1.0) * 0.5;
                    break;

                case kDebugShadersModeTexCoord:
                    // Visualize UV coordinates: U=red, V=green
                    color = float3(in.texCoord.x, in.texCoord.y, 0.0);
                    break;

                case kDebugShadersModeTangent:
                    // Visualize tangents: map from [-1,1] to [0,1] color range
                    color = (normalize(in.worldTangent) + 1.0) * 0.5;
                    break;

                case kDebugShadersModeBitangent:
                    // Visualize bitangents: map from [-1,1] to [0,1] color range
                    color = (normalize(in.worldBitangent) + 1.0) * 0.5;
                    break;

                case kDebugShadersModeWorldPosition:
                    // Visualize world position (normalized to a reasonable range)
                    color = fract(in.worldPosition * 0.1);
                    break;

                case kDebugShadersModeLocalPosition:
                    // Visualize local/model space position
                    color = (in.localPosition + 1.0) * 0.5;
                    break;

                case kDebugShadersModeUVDistortion: {
                    // Check UV distortion using a checkerboard pattern
                    // Areas with high distortion will show smaller/irregular squares
                    float checker = sin(in.texCoord.x * 20.0) * sin(in.texCoord.y * 20.0);
                    color = checker > 0 ? float3(1, 1, 1) : float3(0, 0, 0);
                    // Highlight UV seams and distortion with color coding
                    float2 uvDeriv = fwidth(in.texCoord) * 100.0;
                    color = mix(color, float3(1, 0, 0), saturate(length(uvDeriv) - 1.0));
                    break;
                }

                case kDebugShadersModeTBNMatrix: {
                    // Check if TBN matrix is orthonormal (should be for valid tangent space)
                    float3 N = normalize(in.worldNormal);
                    float3 T = normalize(in.worldTangent);
                    float3 B = normalize(in.worldBitangent);

                    // Check orthogonality (dot products should be near 0)
                    float TdotN = abs(dot(T, N));
                    float TdotB = abs(dot(T, B));
                    float BdotN = abs(dot(B, N));

                    // Green = good (orthogonal), Red = bad (not orthogonal)
                    float orthoQuality = 1.0 - max(max(TdotN, TdotB), BdotN) * 10.0;
                    color = mix(float3(1, 0, 0), float3(0, 1, 0), saturate(orthoQuality));
                    break;
                }

                case kDebugShadersModeVertexID: {
                    // Color based on primitive ID - useful for seeing triangle structure
                    float id = float(primitive_id) * 0.01;
                    color = float3(fract(id), fract(id * 7.0), fract(id * 13.0));
                    break;
                }

                case kDebugShadersModeFaceNormal: {
                    // Calculate face normal from derivatives
                    float3 dPdx = dfdx(in.worldPosition);
                    float3 dPdy = dfdy(in.worldPosition);
                    float3 faceNormal = normalize(cross(dPdx, dPdy));
                    color = (faceNormal + 1.0) * 0.5;
                    break;
                }

                case kDebugShadersModeUVDerivatives: {
                    // Show UV derivatives - useful for understanding texture sampling
                    float2 dUVdx = dfdx(in.texCoord);
                    float2 dUVdy = dfdy(in.texCoord);
                    // Map derivatives to color (scaled for visibility)
                    color = float3(length(dUVdx) * 10.0, length(dUVdy) * 10.0, 0.0);
                    break;
                }

                case kDebugShadersModeCheckerboard: {
                    // Simple checkerboard pattern for UV visualization
                    float checkSize = 10.0;
                    bool checkX = fmod(floor(in.texCoord.x * checkSize), 2.0) > 0.5;
                    bool checkY = fmod(floor(in.texCoord.y * checkSize), 2.0) > 0.5;
                    color = (checkX != checkY) ? float3(1, 1, 1) : float3(0.2, 0.2, 0.2);
                    break;
                }

                case kDebugShadersModeUVGrid: {
                    // UV grid with coordinate lines
                    float gridSize = 10.0;
                    float lineWidth = 0.02;

                    // Grid lines
                    float2 grid = fract(in.texCoord * gridSize);
                    bool isGridLine = (grid.x < lineWidth || grid.x > (1.0 - lineWidth) ||
                                       grid.y < lineWidth || grid.y > (1.0 - lineWidth));

                    // Major grid lines at 0.5
                    float2 majorGrid = fract(in.texCoord * 2.0);
                    bool isMajorLine = (majorGrid.x < lineWidth * 2.0 || majorGrid.x > (1.0 - lineWidth * 2.0) ||
                                        majorGrid.y < lineWidth * 2.0 || majorGrid.y > (1.0 - lineWidth * 2.0));

                    // Base color shows UV coordinates
                    color = float3(in.texCoord.x, in.texCoord.y, 0.5);

                    // Overlay grid
                    if (isMajorLine) {
                        color = float3(1, 1, 0); // Yellow for major lines
                    } else if (isGridLine) {
                        color = float3(0.5, 0.5, 0.5); // Gray for minor lines
                    }
                    break;
                }

                case kDebugShadersModeDepth: {
                    // Visualize depth (distance from camera)
                    float depth = length(in.worldPosition); // Or use in.position.z for screen depth
                    depth = saturate(depth / 10.0); // Adjust scale as needed
                    color = float3(depth, depth, depth);
                    break;
                }

                case kDebugShadersModeWireframeOverlay: {
                    // Show edges using screen-space derivatives
                    // This creates a wireframe-like effect
                    float3 d = fwidth(in.localPosition);
                    float wireframe = smoothstep(0.0, 0.02, min(min(d.x, d.y), d.z));

                    // Base shading with wireframe overlay
                    float3 baseColor = (normalize(in.worldNormal) + 1.0) * 0.5;
                    color = mix(float3(1, 1, 1), baseColor, wireframe);
                    break;
                }

                case kDebugShadersModeNormalDeviation: {
                    // Compare vertex normal vs face normal
                    float3 vertexNormal = normalize(in.worldNormal);

                    // Calculate face normal from derivatives
                    float3 dPdx = dfdx(in.worldPosition);
                    float3 dPdy = dfdy(in.worldPosition);
                    float3 faceNormal = normalize(cross(dPdx, dPdy));

                    // Calculate deviation
                    float deviation = 1.0 - dot(vertexNormal, faceNormal);

                    // Color code: Green = aligned, Red = different
                    color = mix(float3(0, 1, 0), float3(1, 0, 0), deviation);
                    break;
                }

                case kDebugShadersModeAmplificationID: {
                    // Visualize amplification ID (for multi-view rendering)
                    // Use bright colors for better visibility
                    if (in.amplificationID == 0) {
                        color = float3(1.0, 0.2, 0.2); // Red for view 0
                    } else if (in.amplificationID == 1) {
                        color = float3(0.2, 1.0, 0.2); // Green for view 1
                    } else {
                        // Fallback for more views
                        float id = float(in.amplificationID) * 0.618;
                        color = float3(
                                       0.5 + 0.5 * sin(id * 2.0),
                                       0.5 + 0.5 * sin(id * 3.0),
                                       0.5 + 0.5 * sin(id * 5.0)
                                       );
                    }
                    break;
                }

                case kDebugShadersModeInstanceID: {
                    // Visualize instance ID (for instanced rendering)
                    // Use bright, distinct colors
                    if (in.instanceID == 0) {
                        color = float3(1.0, 0.5, 0.0); // Orange for instance 0
                    } else {
                        float id = float(in.instanceID);
                        color = float3(
                                       0.5 + 0.5 * cos(id * 0.7),
                                       0.5 + 0.5 * cos(id * 1.3),
                                       0.5 + 0.5 * cos(id * 2.1)
                                       );
                    }
                    break;
                }

                case kDebugShadersModeQuadThread: {
                    // Visualize thread index within quadgroup (0-3)
                    // Each thread in the 2x2 quad gets a distinct bright color
                    switch(thread_index_in_quadgroup) {
                        case 0:
                            color = float3(1.0, 0.0, 0.0); // Red - top left
                            break;
                        case 1:
                            color = float3(0.0, 1.0, 0.0); // Green - top right
                            break;
                        case 2:
                            color = float3(0.0, 0.0, 1.0); // Blue - bottom left
                            break;
                        case 3:
                            color = float3(1.0, 1.0, 0.0); // Yellow - bottom right
                            break;
                        default:
                            color = float3(1.0, 0.0, 1.0); // Magenta (shouldn't happen)
                            break;
                    }
                    break;
                }

                case kDebugShadersModeSIMDGroup: {
                    // Visualize SIMD group thread index using actual group size
                    // Color based on position within the SIMD group
                    float t = float(thread_index_in_simdgroup) / float(threads_per_simdgroup);

                    // Create a rainbow gradient across the SIMD group
                    float hue = t * 6.0; // 0 to 6 for full spectrum
                    float c = 1.0;
                    float x = c * (1.0 - abs(fmod(hue, 2.0) - 1.0));

                    if (hue < 1.0) {
                        color = float3(c, x, 0);
                    } else if (hue < 2.0) {
                        color = float3(x, c, 0);
                    } else if (hue < 3.0) {
                        color = float3(0, c, x);
                    } else if (hue < 4.0) {
                        color = float3(0, x, c);
                    } else if (hue < 5.0) {
                        color = float3(x, 0, c);
                    } else {
                        color = float3(c, 0, x);
                    }
                    break;
                }

                case kDebugShadersModeBarycentricCoord: {
                    // Visualize barycentric coordinates as RGB
                    // Each vertex of the triangle corresponds to a pure color channel
                    color = barycentric_coord;
                    break;
                }

                case kDebugShadersModeFrontFacing: {
                    // Green for front-facing, red for back-facing triangles
                    color = front_facing ? float3(0.2, 1.0, 0.2) : float3(1.0, 0.2, 0.2);
                    break;
                }

                case kDebugShadersModeSampleID: {
                    // Visualize MSAA sample ID with distinct colors
                    // Most GPUs have 1, 2, 4, or 8 samples
                    switch(sample_id) {
                        case 0:
                            color = float3(1.0, 0.0, 0.0); // Red
                            break;
                        case 1:
                            color = float3(0.0, 1.0, 0.0); // Green
                            break;
                        case 2:
                            color = float3(0.0, 0.0, 1.0); // Blue
                            break;
                        case 3:
                            color = float3(1.0, 1.0, 0.0); // Yellow
                            break;
                        case 4:
                            color = float3(1.0, 0.0, 1.0); // Magenta
                            break;
                        case 5:
                            color = float3(0.0, 1.0, 1.0); // Cyan
                            break;
                        case 6:
                            color = float3(1.0, 0.5, 0.0); // Orange
                            break;
                        case 7:
                            color = float3(0.5, 0.0, 1.0); // Purple
                            break;
                        default:
                            // Fallback for more samples
                            float t = float(sample_id) / 8.0;
                            color = float3(t, 1.0 - t, 0.5);
                            break;
                    }
                    break;
                }

                case kDebugShadersModePointCoord: {
                    // Visualize point coordinates (for point primitives)
                    // point_coord ranges from 0.0 to 1.0 across a point primitive
                    // Note: This only works when rendering points, not triangles
                    color = float3(point_coord.x, point_coord.y, 0.5);
                    break;
                }

                case kDebugShadersModeDistanceToLight: {
                    // Visualize distance from fragment to light position
                    float distance = length(in.worldPosition - uniforms.lightPosition);
                    // Normalize distance for visualization (adjust scale as needed)
                    float normalizedDistance = saturate(distance / 20.0);
                    // Gradient from white (close) to black (far)
                    color = float3(1.0 - normalizedDistance);
                    break;
                }

                case kDebugShadersModeDistanceToOrigin: {
                    // Visualize distance from fragment to world origin
                    float distance = length(in.worldPosition);
                    // Normalize distance for visualization
                    float normalizedDistance = saturate(distance / 10.0);
                    // Gradient from white (close) to black (far)
                    color = float3(1.0 - normalizedDistance);
                    break;
                }

                case kDebugShadersModeDistanceToCamera: {
                    // Visualize actual 3D distance from fragment to camera
                    // Note: This is different from depth which is just the Z distance
                    float distance = length(in.worldPosition - uniforms.cameraPosition);
                    // Normalize distance for visualization
                    float normalizedDistance = saturate(distance / 15.0);
                    // Gradient from white (close) to black (far)
                    color = float3(1.0 - normalizedDistance);
                    break;
                }

                default:
                    // Fallback: magenta for unknown mode
                    color = float3(1.0, 0.0, 1.0);
                    break;
            }

            return float4(color, 1.0);
        }

    } // namespace FlatShader
