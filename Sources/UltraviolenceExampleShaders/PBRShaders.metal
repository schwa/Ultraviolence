#import <metal_stdlib>
#import <simd/simd.h>
#import <metal_logging>
#import "UltraviolenceExampleShaders.h"

using namespace metal;

namespace PBR {

    typedef PBRMaterial Material;
    typedef PBRUniforms Uniforms;
    typedef PBRAmplifiedUniforms AmplifiedUniforms;
    typedef PBRLight Light;

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
        constant Light* lights [[buffer(3)]],
        constant uint& lightCount [[buffer(4)]],
        texture2d<float> albedoTexture [[texture(0)]],
        texture2d<float> normalTexture [[texture(1)]],
        texture2d<float> metallicRoughnessTexture [[texture(2)]],
        texture2d<float> aoTexture [[texture(3)]],
        texture2d<float> emissiveTexture [[texture(4)]],
        texture2d<float> environmentTexture [[texture(5)]]
      ) {
        constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::repeat);

        // Get camera position for this view
        float3 cameraPos = amplifiedUniforms[in.amplificationID].cameraPosition;

        // Sample textures or use material values
        float3 albedo = uniforms.material.albedo;
        float metallic = uniforms.material.metallic;
        float roughness = uniforms.material.roughness;
        float ao = uniforms.material.ao;


        float3 emissive = uniforms.material.emissive * uniforms.material.emissiveIntensity;

        // If textures are bound, use them instead
        if (!is_null_texture(albedoTexture)) {
            float4 albedoSample = albedoTexture.sample(textureSampler, in.texCoord);
            albedo = albedoSample.rgb;
        }

        if (!is_null_texture(metallicRoughnessTexture)) {
            float4 metallicRoughnessSample = metallicRoughnessTexture.sample(textureSampler, in.texCoord);
            metallic = metallicRoughnessSample.b;  // Blue channel for metallic
            roughness = metallicRoughnessSample.g; // Green channel for roughness
        }

        if (!is_null_texture(aoTexture)) {
            ao = aoTexture.sample(textureSampler, in.texCoord).r;
        }

        if (!is_null_texture(emissiveTexture)) {
            emissive = emissiveTexture.sample(textureSampler, in.texCoord).rgb * uniforms.material.emissiveIntensity;
        }

        // Normal mapping
        float3 N = normalize(in.worldNormal);
        if (!is_null_texture(normalTexture)) {
            float3 normalSample = normalTexture.sample(textureSampler, in.texCoord).rgb;
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
        for (uint i = 0; i < lightCount && i < 16; ++i) {
            Light light = lights[i];

            float3 L;
            float attenuation = 1.0;

            if (light.type == 0) { // Directional light
                // For directional lights, position is the direction TO the light
                L = normalize(light.position);
            } else { // Point light
                L = normalize(light.position - in.worldPosition);
                float distance = length(light.position - in.worldPosition);
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
            if (uniforms.material.softScattering > 0.001) {
                // View-dependent edge softening
                // Slightly offset toward normal
                float3 H_soft = normalize(L + N * 0.3);
                float VdotH = saturate(dot(V, -H_soft));

                // Power function for falloff - different per color channel. Red softens most, blue least
                float3 scatter = pow(saturate(VdotH), float3(1.0, 2.0, 4.0) / uniforms.material.softScatteringDepth);

                // Wrapped diffuse for shadow softening
                float wrap = 0.3;
                float NdotL_wrapped = saturate((dot(N, L) + wrap) / (1.0 + wrap));

                // Edge softening - more effect at grazing angles
                float NdotV = saturate(dot(N, V));
                float edgeSoftness = 1.0 - NdotV * NdotV;

                // Combine wrapped diffuse and edge softening
                float3 softContribution = albedo * uniforms.material.softScatteringTint * radiance * (NdotL_wrapped * 0.5 + scatter * edgeSoftness) * uniforms.material.softScattering;

                Lo += softContribution;
            }

            // Clearcoat layer (additive on top of base layer)
            if (uniforms.material.clearcoat > 0.001) {
                float3 clearcoatF0 = float3(0.04); // IOR 1.5
                float clearcoatRoughness = uniforms.material.clearcoatRoughness;

                // Clearcoat BRDF
                float clearcoatNDF = distributionGGX(N, H, clearcoatRoughness);
                float clearcoatG = geometrySmith(N, V, L, clearcoatRoughness);
                float3 clearcoatF = fresnelSchlick(max(dot(H, V), 0.0), clearcoatF0);

                float3 clearcoatBRDF = (clearcoatNDF * clearcoatG * clearcoatF) /
                                       (4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001);

                // Add clearcoat contribution
                Lo += clearcoatBRDF * radiance * NdotL * uniforms.material.clearcoat;
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

            environmentContribution = (diffuseEnv + specularEnv) * ao;

            // Clearcoat environment reflection
            if (uniforms.material.clearcoat > 0.001) {
                float3 clearcoatF0 = float3(0.04);
                float3 clearcoatF = fresnelSchlick(max(dot(N, V), 0.0), clearcoatF0);

                // Sample environment at clearcoat roughness
                float clearcoatMipLevel = uniforms.material.clearcoatRoughness * 8.0;
                float3 clearcoatEnv = environmentTexture.sample(envSampler, envUV, level(clearcoatMipLevel)).rgb;

                // Add clearcoat environment contribution
                environmentContribution += clearcoatEnv * clearcoatF * uniforms.material.clearcoat * ao;
            }
        }

        // Ambient lighting (simple approximation) - increased for visibility
        float3 ambient = float3(0.2) * albedo * ao;

        float3 color = ambient + Lo + emissive + environmentContribution;

        // Tone mapping (Reinhard)
        color = color / (color + float3(1.0));

        // Gamma correction
        color = pow(color, float3(1.0/2.2));

        return float4(color, 1.0);
    }

} // namespace PBR
