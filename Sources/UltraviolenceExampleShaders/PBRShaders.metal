#import <metal_stdlib>
#import <simd/simd.h>
#import <metal_logging>
#import "UltraviolenceExampleShaders.h"

using namespace metal;

namespace PBR {
    typedef PBRUniforms Uniforms;
    typedef PBRAmplifiedUniforms AmplifiedUniforms;

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
        uint amplificationID [[flat]];
    };

    // PBR Helper Functions

    // Fresnel-Schlick approximation
    float3 fresnelSchlick(float cosTheta, float3 F0) {
        return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
    }

    // Distribution function (GGX/Trowbridge-Reitz)
    float distributionGGX(float3 N, float3 H, float roughness) {
        float a = roughness * roughness;
        float a2 = a * a;
        float NdotH = max(dot(N, H), 0.0);
        float NdotH2 = NdotH * NdotH;

        float num = a2;
        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
        denom = M_PI_F * denom * denom;

        return num / denom;
    }

    // Geometry function (Smith's method)
    float geometrySchlickGGX(float NdotV, float roughness) {
        float r = (roughness + 1.0);
        float k = (r * r) / 8.0;

        float num = NdotV;
        float denom = NdotV * (1.0 - k) + k;

        return num / denom;
    }

    float geometrySmith(float3 N, float3 V, float3 L, float roughness) {
        float NdotV = max(dot(N, V), 0.0);
        float NdotL = max(dot(N, L), 0.0);
        float ggx2 = geometrySchlickGGX(NdotV, roughness);
        float ggx1 = geometrySchlickGGX(NdotL, roughness);

        return ggx1 * ggx2;
    }

    // Helper function to convert direction to equirectangular UV
    float2 directionToEquirectangularUV(float3 direction) {
        float phi = atan2(direction.z, direction.x);
        float theta = asin(direction.y);
        float u = (phi + M_PI_F) / (2.0 * M_PI_F);
        float v = (theta + M_PI_F / 2.0) / M_PI_F;
        return float2(u, v);
    }

    // MARK: -

    // Vertex shader
    vertex VertexOut vertex_main(VertexIn in [[stage_in]],
        uint vertex_id [[vertex_id]],
        uint instance_id [[instance_id]],
        uint amplification_id [[amplification_id]],
        constant FrameUniforms& frameUniforms [[buffer(0)]],
        constant Uniforms& uniforms [[buffer(1)]],
        constant AmplifiedUniforms *amplifiedUniforms [[buffer(2)]]
    ) {
        float4x4 modelMatrix = uniforms.modelMatrix;

        VertexOut out;
        // Transform position to world space
        float4 worldPosition = modelMatrix * float4(in.position, 1.0);

        out.worldPosition = worldPosition.xyz;

        // Transform position to clip space
        out.position = amplifiedUniforms[amplification_id].viewProjectionMatrix * worldPosition;

        // Transform normal, tangent, and bitangent to world space
        out.worldNormal = normalize(uniforms.normalMatrix * in.normal);
        out.worldTangent = normalize(uniforms.normalMatrix * in.tangent);
        out.worldBitangent = normalize(uniforms.normalMatrix * in.bitangent);

        // Pass through texture coordinates
        out.texCoord = in.texCoord;

        // Pass through amplification ID for fragment shader
        out.amplificationID = amplification_id;
        return out;
    }

    // PBR Fragment shader
    fragment float4 fragment_main(
        VertexOut in [[stage_in]],
        constant FrameUniforms& frameUniforms [[buffer(0)]],
        constant Uniforms& uniforms [[buffer(1)]],
        constant AmplifiedUniforms *amplifiedUniforms [[buffer(2)]],
        constant PBRMaterialArgumentBuffer& material [[buffer(3)]],
        constant Light* lights [[buffer(4)]],
        constant LightingArgumentBuffer &lighting [[buffer(5)]],
        texture2d<float> environmentTexture [[texture(5)]]
    ) {
        constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::repeat);

        // Get camera position for this view
        float3 cameraPos = amplifiedUniforms[in.amplificationID].cameraPosition;

        // Sample textures or use material values
        float3 albedo = resolveSpecifiedColor(material.albedo, in.texCoord).rgb;
        float metallic = resolveSpecifiedColor(material.metallic, in.texCoord).r;
        float roughness = resolveSpecifiedColor(material.roughness, in.texCoord).r;
        float ambientOcclusion = resolveSpecifiedColor(material.ambientOcclusion, in.texCoord).r;
        float3 emissive = resolveSpecifiedColor(material.emissive, in.texCoord).rgb * material.emissiveIntensity;

        // Normal mapping
        float3 N = normalize(in.worldNormal);
        if (!is_null_texture(material.normal)) {
            float3 normalSample = material.normal.sample(textureSampler, in.texCoord).xyz;
            normalSample = normalSample * 2.0 - 1.0; // Convert from [0,1] to [-1,1]

            // Create TBN matrix
            float3 T = normalize(in.worldTangent);
            float3 B = normalize(in.worldBitangent);
            float3x3 TBN = float3x3(T, B, N);

            N = normalize(TBN * normalSample);
        }

        // View direction
        float3 V = normalize(cameraPos - in.worldPosition);

        // Calculate reflectance at normal incidence (F0)
        float3 F0 = float3(0.04); // Default for dielectrics
        F0 = mix(F0, albedo, metallic);

        // Reflectance equation
        float3 Lo = float3(0.0);

        // Calculate lighting from each light source
        for (int i = 0; i < lighting.lightCount && i < 16; ++i) {
            const Light light = lighting.lights[i];
            const float3 lightPosition = lighting.lightPositions[i];

            float3 L;
            float attenuation = 1.0;

            if (light.type == 0) { // Directional light
                // For directional lights, position is the direction TO the light
                L = normalize(lightPosition);
            } else { // Point light
                L = normalize(lightPosition - in.worldPosition);
                float distance = length(lightPosition - in.worldPosition);
                attenuation = 1.0 / (distance * distance);
            }

            // Calculate half vector
            float3 H = normalize(V + L);

            // Calculate radiance
            float3 radiance = light.color * light.intensity * attenuation;

            // Cook-Torrance BRDF
            float NDF = distributionGGX(N, H, roughness);
            float G = geometrySmith(N, V, L, roughness);
            float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

            // Calculate BRDF
            float3 numerator = NDF * G * F;
            float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001; // Prevent divide by zero
            float3 specular = numerator / denominator;

            // kS is equal to Fresnel
            float3 kS = F;
            // For energy conservation, the diffuse and specular light can't
            // be above 1.0 (unless the surface emits light); to preserve this
            // relationship the diffuse component (kD) should equal 1.0 - kS.
            float3 kD = float3(1.0) - kS;
            // Multiply kD by the inverse metalness such that only non-metals
            // have diffuse lighting, or a linear blend if partly metal
            kD *= 1.0 - metallic;

            // Scale light by NdotL
            float NdotL = max(dot(N, L), 0.0);

            // Add to outgoing radiance Lo
            Lo += (kD * albedo / M_PI_F + specular) * radiance * NdotL;

            // Soft scattering - cheap subsurface scattering approximation
            // Simulates light diffusion within translucent materials like wax, skin, or marble
            if (material.softScattering > 0.001) {
                // View-dependent edge softening
                // Slightly offset toward normal
                float3 H_soft = normalize(L + N * 0.3);
                float VdotH = saturate(dot(V, -H_soft));

                // Power function for falloff - different per color channel. Red softens most, blue least
                float3 scatter = pow(saturate(VdotH), float3(1.0, 2.0, 4.0) / material.softScatteringDepth);

                // Wrapped diffuse for shadow softening
                float wrap = 0.3;
                float NdotL_wrapped = saturate((dot(N, L) + wrap) / (1.0 + wrap));

                // Edge softening - more effect at grazing angles
                float NdotV = saturate(dot(N, V));
                float edgeSoftness = 1.0 - NdotV * NdotV;

                // Combine wrapped diffuse and edge softening
                float3 softContribution = albedo * material.softScatteringTint * radiance * (NdotL_wrapped * 0.5 + scatter * edgeSoftness) * material.softScattering;

                Lo += softContribution;
            }

            // Clearcoat layer (additive on top of base layer)
            if (material.clearcoat > 0.001) {
                float3 clearcoatF0 = float3(0.04); // IOR 1.5
                float clearcoatRoughness = material.clearcoatRoughness;

                // Clearcoat BRDF
                float clearcoatNDF = distributionGGX(N, H, clearcoatRoughness);
                float clearcoatG = geometrySmith(N, V, L, clearcoatRoughness);
                float3 clearcoatF = fresnelSchlick(max(dot(H, V), 0.0), clearcoatF0);

                float3 clearcoatBRDF = (clearcoatNDF * clearcoatG * clearcoatF) /
                                       (4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001);

                // Add clearcoat contribution
                Lo += clearcoatBRDF * radiance * NdotL * material.clearcoat;
            }
        }

        // Environment reflections (IBL) - using equirectangular environment map
        float3 environmentContribution = float3(0.0);
        if (!is_null_texture(environmentTexture)) {
            constexpr sampler envSampler(mag_filter::linear, min_filter::linear, mip_filter::linear, address::clamp_to_edge);

            // Calculate reflection vector
            float3 R = reflect(-V, N);

            // Convert reflection vector to equirectangular UV coordinates
            float2 envUV = directionToEquirectangularUV(R);

            // Sample environment map - use roughness for mip level
            float mipLevel = roughness * 8.0; // Assume 8 mip levels
            float3 envColor = environmentTexture.sample(envSampler, envUV, level(mipLevel)).rgb;

            // Apply fresnel for environment reflections
            float3 F = fresnelSchlick(max(dot(N, V), 0.0), F0);

            // Mix based on metalness and roughness
            float3 kS = F;
            float3 kD = 1.0 - kS;
            kD *= 1.0 - metallic;

            // Sample diffuse irradiance (using normal direction)
            float2 irradianceUV = directionToEquirectangularUV(N);
            float3 irradiance = environmentTexture.sample(envSampler, irradianceUV, level(8.0)).rgb * 0.3;

            // Add environment contribution
            float3 diffuseEnv = irradiance * albedo * kD;
            float3 specularEnv = envColor * F;

            environmentContribution = (diffuseEnv + specularEnv) * ambientOcclusion;

            // Clearcoat environment reflection
            if (material.clearcoat > 0.001) {
                float3 clearcoatF0 = float3(0.04);
                float3 clearcoatF = fresnelSchlick(max(dot(N, V), 0.0), clearcoatF0);

                // Sample environment at clearcoat roughness
                float clearcoatMipLevel = material.clearcoatRoughness * 8.0;
                float3 clearcoatEnv = environmentTexture.sample(envSampler, envUV, level(clearcoatMipLevel)).rgb;

                // Add clearcoat environment contribution
                environmentContribution += clearcoatEnv * clearcoatF * material.clearcoat * ambientOcclusion;
            }
        }

        // Ambient lighting (simple approximation) - increased for visibility
        float3 ambient = float3(0.2) * albedo * ambientOcclusion;

        float3 color = ambient + Lo + emissive + environmentContribution;

        // Tone mapping (Reinhard)
        color = color / (color + float3(1.0));

        // Gamma correction
        color = pow(color, float3(1.0/2.2));

        return float4(color, 1.0);
    }

} // namespace PBR
