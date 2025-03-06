#import <metal_stdlib>
#import <simd/simd.h>
//#include "include/BlinnPhongShaders.h"
//#include "include/Support.h"
//#include "include/Shaders.h"
#import "include/BlinnPhongShaders.h"

// https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model

using namespace metal;

namespace BlinnPhong {

    struct Vertex {
        simd_float3 position ATTRIBUTE(0);
        simd_float3 normal ATTRIBUTE(1);
        simd_float2 textureCoordinate ATTRIBUTE(2);
    };

    float3 CalculateBlinnPhong(float3 modelPosition, float3 cameraPosition, float3 normal, constant BlinnPhongLightingModelArgumentBuffer &lightingModel, float shininess, float3 ambientColor, float3 diffuseColor, float3 specularColor);

    // ----------------------------------------------------------------------

    // MARK: Constants

    //constant int kPhongMode [[ function_constant(0)]];

    // MARK: Types

    struct Fragment {
        float4 position [[position]]; // in projection space
        float3 worldPosition;
        float3 normal;
        float2 textureCoordinate;
        uint instance_id;
    };

    // MARK: Shaders

    [[vertex]]
    Fragment vertex_main(
        uint instance_id [[instance_id]],
        Vertex in [[stage_in]],
        constant Transforms *transforms [[buffer(1)]]
        )
    {
        Fragment out;
        const float4 position = float4(in.position, 1.0);
        const float4 modelVertex = transforms[instance_id].modelViewMatrix * position;
        out.position = transforms[instance_id].modelViewProjectionMatrix * position;
        out.worldPosition = float3(modelVertex) / modelVertex.w;
        out.normal = normalize(transforms[instance_id].modelNormalMatrix * in.normal);
        out.textureCoordinate = in.textureCoordinate;
        out.instance_id = instance_id;
        return out;
    }

    [[fragment]]
    float4 fragment_main(
                         Fragment in [[stage_in]],
                         constant BlinnPhongLightingModelArgumentBuffer &lightingModel [[buffer(1)]],
                         constant BlinnPhongMaterialArgumentBuffer *material [[buffer(2)]],
                         constant Transforms *transforms [[buffer(3)]]
                         )
    {
        uint instance_id = in.instance_id;

        float3 ambientColor;
        if (material[instance_id].ambientSource == kColorSourceColor) {
            ambientColor = material[instance_id].ambientColor.xyz;
        }
        else {
            ambientColor = material[instance_id].ambientTexture.sample(material[instance_id].ambientSampler, in.textureCoordinate).rgb;
        }

        float3 diffuseColor;
        if (material[instance_id].diffuseSource == kColorSourceColor) {
            diffuseColor = material[instance_id].diffuseColor.xyz;
        }
        else {
            diffuseColor = material[instance_id].diffuseTexture.sample(material[instance_id].diffuseSampler, in.textureCoordinate).rgb;
        }

        float3 specularColor;
        if (material[instance_id].specularSource == kColorSourceColor) {
            specularColor = material[instance_id].specularColor.xyz;
        }
        else {
            specularColor = material[instance_id].specularTexture.sample(material[instance_id].specularSampler, in.textureCoordinate).rgb;
        }

        auto cameraPosition = transforms[instance_id].cameraMatrix.columns[3].xyz;

        float3 color = CalculateBlinnPhong(in.worldPosition, cameraPosition, in.normal, lightingModel, material[instance_id].shininess, ambientColor, diffuseColor, specularColor);
        return float4(color, 1.0);
    }

    // MARK: Helper Functions

    /// Computes the Blinn-Phong or Phong lighting model for a given surface point.
    ///
    /// This function calculates the color contribution from ambient, diffuse, and specular lighting
    /// for a surface based on the Blinn-Phong or Phong reflection model. It supports multiple light
    /// sources, applies attenuation based on distance, and determines specular highlights based on
    /// the selected shading model.
    ///
    /// - Parameters:
    ///   - modelPosition: The world-space position of the surface point.
    ///   - cameraPosition: The world-space position of the camera.
    ///   - normal: The normalized surface normal at the surface point.
    ///   - lightingModel: A buffer containing all active lights in the scene.
    ///   - shininess: The shininess exponent controlling the size of specular highlights.
    ///   - ambientColor: The base ambient color contribution.
    ///   - diffuseColor: The base diffuse color contribution.
    ///   - specularColor: The base specular color contribution.
    ///
    /// - Returns: The final computed color at the surface point, incorporating ambient, diffuse, and specular lighting.
    float3 CalculateBlinnPhong(
        const float3 modelPosition,
        const float3 cameraPosition,
        const float3 normal,
        constant BlinnPhongLightingModelArgumentBuffer &lightingModel,
        const float shininess,
        const float3 ambientColor,
        const float3 diffuseColor,
        const float3 specularColor)
    {
        const bool phongMode = false; // Use Blinn-Phong shading by default
        float3 accumulatedDiffuseColor = float3(0.0);
        float3 accumulatedSpecularColor = float3(0.0);

        // Compute Lambertian reflection (diffuse lighting). The dot product measures how aligned the normal is with the light direction. If the normal faces away from the light, the dot product will be negative, so we clamp it to 0.
        const float3 viewDirection = normalize(cameraPosition - modelPosition);

        for (int index = 0; index < lightingModel.lightCount; ++index) {
            const auto light = lightingModel.lights[index];

            // Compute the direction from the surface point to the light source
            float3 lightDirection = light.lightPosition - modelPosition;
            const float distanceSquared = length_squared(lightDirection);
            lightDirection = normalize(lightDirection);

            // Compute Lambertian reflection (diffuse lighting). The dot product measures how aligned the normal is with the light direction. If the normal faces away from the light, the dot product will be negative, so we clamp it to 0.
            const float lambertian = max(dot(lightDirection, normal), 0.0);
            if (lambertian == 0.0) {
                continue; // No contribution from this light if it does not reach the surface
            }

            // Apply attenuation to simulate how light weakens over distance. This is a standard quadratic falloff model: 1 / (a + b*d + c*d²). The constants 0.09 and 0.032 are chosen to approximate realistic light falloff. Higher values make light fall off more quickly.
            const float attenuation = 1.0 / (1.0 + 0.09 * distanceSquared + 0.032 * distanceSquared * distanceSquared);

            float specular = 0.0;

            if (!phongMode) {
                // Blinn-Phong Specular Reflection: Instead of computing the perfect reflection direction (like Phong), Blinn-Phong uses the halfway vector (H) between the light direction (L) and the view direction (V). This acts as an "approximate" reflection direction. H = (L + V) / |L + V|. The normal is then compared to this halfway vector to determine the intensity of the specular highlight.
                // https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model
                const float3 halfDirection = normalize(lightDirection + viewDirection);
                specular = pow(max(dot(halfDirection, normal), 0.0), shininess);
            } else {
                // Phong Specular Reflection: This method explicitly calculates the reflection of the light direction (L) across the normal (N) and compares it with the view direction (V). R = 2 * (N · L) * N - L. The specular intensity is based on how well the reflected vector aligns with V.
                // https://en.wikipedia.org/wiki/Phong_reflection_model
                const float3 reflectionDirection = reflect(-lightDirection, normal);
                specular = pow(max(dot(reflectionDirection, viewDirection), 0.0), shininess);
            }

            // Scale light intensity based on its color, power, and attenuation factor
            const float3 lightContribution = light.lightColor * light.lightPower * attenuation;

            // Accumulate diffuse and specular contributions from this light source
            accumulatedDiffuseColor += diffuseColor * lambertian * lightContribution;
            accumulatedSpecularColor += specularColor * specular * lightContribution;
        }

        // Compute final color by combining ambient, diffuse, and specular components.
        return lightingModel.ambientLightColor * ambientColor + accumulatedDiffuseColor + accumulatedSpecularColor;
    }

}
