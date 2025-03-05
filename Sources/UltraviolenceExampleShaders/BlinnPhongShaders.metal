#import <metal_stdlib>
#import <simd/simd.h>
//#include "include/BlinnPhongShaders.h"
//#include "include/Support.h"
//#include "include/Shaders.h"
#import "include/BlinnPhongShaders.h"

// https://en.wikipedia.org/wiki/Blinn–Phong_reflection_model

using namespace metal;

namespace BlinnPhong {

    float3 CalculateBlinnPhong(float3 modelPosition,
                               float3 cameraPosition,
                               float3 interpolatedNormal,
                               constant BlinnPhongLightingModelArgumentBuffer &lightingModel,
                               float shininess,
                               float3 ambientColor,
                               float3 diffuseColor,
                               float3 specularColor
                               );

    // ----------------------------------------------------------------------

    // MARK: Constants

    //constant int kPhongMode [[ function_constant(0)]];

    // MARK: Types


    struct Fragment {
        float4 position [[position]]; // in projection space
        float3 modelPosition;
        float3 interpolatedNormal;
        float2 textureCoordinate;
        uint instance_id;
    };


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
        out.modelPosition = float3(modelVertex) / modelVertex.w;
        out.interpolatedNormal = transforms[instance_id].modelNormalMatrix * in.normal;
        out.textureCoordinate = in.textureCoordinate;
        out.instance_id = instance_id;
        return out;
    }

    [[fragment]]
    float4 fragment_main(
                         Fragment in [[stage_in]],
                         constant BlinnPhongLightingModelArgumentBuffer &lightingModel [[buffer(1)]],
                         constant BlinnPhongMaterialArgumentBuffer *material [[buffer(2)]],
                         constant Transforms *transforms_f [[buffer(3)]]
                         )
    {
        uint instance_id = in.instance_id;

        float3 ambientColor;
        if (material[instance_id].ambientSource == texture) {
            ambientColor = material[instance_id].ambientColor.xyz;
        }
        else {
            ambientColor = material[instance_id].ambientTexture.sample(material[instance_id].ambientSampler, in.textureCoordinate).rgb;
        }

        float3 diffuseColor;
        if (material[instance_id].diffuseSource == texture) {
            diffuseColor = material[instance_id].diffuseColor.xyz;
        }
        else {
            diffuseColor = material[instance_id].diffuseTexture.sample(material[instance_id].diffuseSampler, in.textureCoordinate).rgb;
        }

        float3 specularColor;
        if (material[instance_id].specularSource == texture) {
            specularColor = material[instance_id].specularColor.xyz;
        }
        else {
            specularColor = material[instance_id].specularTexture.sample(material[instance_id].specularSampler, in.textureCoordinate).rgb;
        }

        auto cameraPosition = transforms_f[instance_id].cameraMatrix.columns[3].xyz;

        float3 color = CalculateBlinnPhong(in.modelPosition,
                                           cameraPosition,
                                           in.interpolatedNormal, lightingModel, material[instance_id].shininess, ambientColor, diffuseColor, specularColor);
        return float4(color, 1.0);
    }

    // MARK: Helper Functions

    float3 CalculateBlinnPhong(float3 modelPosition,
                               float3 cameraPosition,
                               float3 interpolatedNormal,
                               constant BlinnPhongLightingModelArgumentBuffer &lightingModel,
                               float shininess,
                               float3 ambientColor,
                               float3 diffuseColor,
                               float3 specularColor
                               )
    {

        float3 accumulatedDiffuseColor = { 0, 0, 0 };
        float3 accumulatedSpecularColor = { 0, 0, 0 };

        for (int index = 0; index != lightingModel.lightCount; ++index) {
            const auto light = lightingModel.lights[index];
            const float3 normal = normalize(interpolatedNormal);
            float3 lightDir = lightingModel.lights[index].lightPosition - modelPosition;
            float distance = length(lightDir);
            distance = distance * distance;
            lightDir = normalize(lightDir);

            const float lambertian = max(dot(lightDir, normal), 0.0);
            float specular = 0.0;

            float attenuation = 1.0 / (1.0 + 0.09 * distance + 0.032 * distance * distance);
            if (lambertian > 0.0)
            {
                const float3 viewDir = normalize(cameraPosition - modelPosition);
                int kPhongMode = 0;
                if (kPhongMode == 0)
                {
                    const float3 halfDir = normalize(lightDir + viewDir);
                    const float specularAngle = max(dot(halfDir, normal), 0.0);
                    specular = pow(specularAngle, shininess);
                }
                else
                {
                    // this is phong (for comparison)
                    const float3 reflectDir = reflect(-lightDir, normal);
                    const float specularAngle = max(dot(reflectDir, viewDir), 0.0);
                    // note that the exponent is different here
                    specular = pow(specularAngle, shininess / 4.0);
                }
            }
            accumulatedDiffuseColor += diffuseColor * lambertian * light.lightColor * light.lightPower * attenuation;
            accumulatedSpecularColor += specularColor * specular * light.lightColor * light.lightPower * attenuation;        }

        float3 finalColor = lightingModel.ambientLightColor * ambientColor + accumulatedDiffuseColor + accumulatedSpecularColor;
        return finalColor;
    }

}
