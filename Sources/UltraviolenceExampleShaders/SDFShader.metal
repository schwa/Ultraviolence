#import "SDFShader.h"
#import "UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace SDFShader {

    struct VertexIn {
        float3 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    struct FragmentOut {
        float4 color [[color(0)]];
        float depth [[depth(any)]];
    };

    [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 1.0);
        out.uv = in.position.xy;
        return out;
    }

    // SDF Primitives
    float sdSphere(float3 p, float r) {
        return length(p) - r;
    }

    float sdBox(float3 p, float3 b) {
        float3 q = abs(p) - b;
        return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    }

    float sdTorus(float3 p, float2 t) {
        float2 q = float2(length(p.xz) - t.x, p.y);
        return length(q) - t.y;
    }

    float sdOctahedron(float3 p, float s) {
        p = abs(p);
        float m = p.x + p.y + p.z - s;
        float3 q;
        if (3.0 * p.x < m)
            q = p.xyz;
        else if (3.0 * p.y < m)
            q = p.yzx;
        else if (3.0 * p.z < m)
            q = p.zxy;
        else
            return m * 0.57735027;
        float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
        return length(float3(q.x, q.y - s + k, q.z - k));
    }

    // SDF Operations
    float opUnion(float d1, float d2) {
        return min(d1, d2);
    }

    float opSubtraction(float d1, float d2) {
        return max(-d1, d2);
    }

    float opIntersection(float d1, float d2) {
        return max(d1, d2);
    }

    float opSmoothUnion(float d1, float d2, float k) {
        float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
        return mix(d2, d1, h) - k * h * (1.0 - h);
    }

    // Transform operations
    float3 opRepeat(float3 p, float3 c) {
        // Safer modulo operation that avoids division by zero
        float3 result;
        result.x = (c.x > 0.0) ? (p.x - c.x * floor(p.x / c.x)) - 0.5 * c.x : p.x;
        result.y = (c.y > 0.0) ? (p.y - c.y * floor(p.y / c.y)) - 0.5 * c.y : p.y;
        result.z = (c.z > 0.0) ? (p.z - c.z * floor(p.z / c.z)) - 0.5 * c.z : p.z;
        return result;
    }

    float3 opTwist(float3 p, float k) {
        float c = cos(k * p.y);
        float s = sin(k * p.y);
        float2x2 m = float2x2(c, -s, s, c);
        return float3(m * p.xz, p.y);
    }

    // Scene SDF
    float sceneSDF(float3 p, float time) {
        // Sphere stays at origin
        float sphere = sdSphere(p, 0.8);

        // Box orbits around
        float3 p2 = p;
        p2.x -= cos(time * 0.6) * 1.5;
        p2.z -= sin(time * 0.6) * 1.5;
        p2.y -= sin(time * 0.8) * 0.5;
        float box = sdBox(p2, float3(0.6, 0.6, 0.6));

        // Torus moves in figure-8 pattern
        float3 p3 = p;
        p3.x -= sin(time * 0.7) * 1.2;
        p3.z -= sin(time * 1.4) * 0.8;
        p3.y -= cos(time * 0.5) * 0.6;
        float torus = sdTorus(p3, float2(0.7, 0.25));

        // Octahedron moves up and down and side to side
        float3 p4 = p;
        p4.x -= sin(time * 0.4) * 1.0;
        p4.y -= cos(time * 0.9) * 1.2;
        p4.z -= cos(time * 0.5) * 0.8;
        float octahedron = sdOctahedron(p4, 0.7);

        // Dynamic blending - varies smoothness over time
        float blendAmount = (sin(time * 0.3) * 0.5 + 0.5) * 0.25 + 0.1;

        // Combine shapes with time-varying smooth union
        float d = opSmoothUnion(sphere, box, blendAmount);
        d = opSmoothUnion(d, torus, blendAmount);
        d = opSmoothUnion(d, octahedron, blendAmount);

        return d;
    }

    // Calculate normal using gradient
    float3 calcNormal(float3 p, float time) {
        const float eps = 0.001;
        float3 n;
        n.x = sceneSDF(p + float3(eps, 0, 0), time) - sceneSDF(p - float3(eps, 0, 0), time);
        n.y = sceneSDF(p + float3(0, eps, 0), time) - sceneSDF(p - float3(0, eps, 0), time);
        n.z = sceneSDF(p + float3(0, 0, eps), time) - sceneSDF(p - float3(0, 0, eps), time);
        return normalize(n);
    }

    // Soft shadow
    float softShadow(float3 ro, float3 rd, float mint, float maxt, float k, float time) {
        float res = 1.0;
        float t = mint;
        for (int i = 0; i < 16; i++) {
            float h = sceneSDF(ro + rd * t, time);
            res = min(res, k * h / t);
            t += clamp(h, 0.02, 0.10);
            if (h < 0.001 || t > maxt)
                break;
        }
        return clamp(res, 0.0, 1.0);
    }

    // Ambient occlusion
    float ambientOcclusion(float3 p, float3 n, float time) {
        float occ = 0.0;
        float sca = 1.0;
        for (int i = 0; i < 5; i++) {
            float h = 0.01 + 0.12 * float(i) / 4.0;
            float d = sceneSDF(p + h * n, time);
            occ += (h - d) * sca;
            sca *= 0.95;
        }
        return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
    }

    // Ray marching - returns color and hit distance
    struct RayMarchResult {
        float3 color;
        float distance;
    };

    RayMarchResult rayMarch(float3 ro, float3 rd, float time) {
        const int maxSteps = 100;
        const float maxDist = 50.0;
        const float epsilon = 0.001;

        RayMarchResult result;
        float t = 0.0;

        for (int i = 0; i < maxSteps; i++) {
            float3 p = ro + rd * t;
            float d = sceneSDF(p, time);

            if (d < epsilon) {
                // Hit - calculate lighting
                float3 normal = calcNormal(p, time);
                float3 lightDir = normalize(float3(sin(time * 0.5), 1.0, cos(time * 0.5)));

                // Basic lighting
                float diff = max(dot(normal, lightDir), 0.0);
                float spec = pow(max(dot(reflect(-lightDir, normal), -rd), 0.0), 32.0);
                float ao = ambientOcclusion(p, normal, time);
                float shadow = softShadow(p + normal * 0.002, lightDir, 0.002, 10.0, 8.0, time);

                // Material colors with variation based on position - vibrant palette
                float3 baseColor = float3(0.4, 0.6, 1.0); // Bright blue
                float3 color2 = float3(0.9, 0.3, 0.6);    // Magenta
                float3 color3 = float3(0.3, 1.0, 0.8);    // Cyan

                // Blend colors based on position and time
                float blend1 = sin(p.x * 2.0 + time) * 0.5 + 0.5;
                float blend2 = sin(p.y * 2.0 - time * 0.7) * 0.5 + 0.5;

                baseColor = mix(baseColor, color2, blend1);
                baseColor = mix(baseColor, color3, blend2 * 0.5);

                float3 color = baseColor * (0.2 + 0.8 * diff * shadow) + float3(1.0) * spec * shadow;
                color *= ao;

                // Add fog
                color = mix(color, float3(0.1, 0.1, 0.15), 1.0 - exp(-t * 0.05));

                result.color = color;
                result.distance = t;
                return result;
            }

            t += d;
            if (t > maxDist)
                break;
        }

        // Solid background color - no hit
        result.color = float3(0.08, 0.08, 0.12);
        result.distance = maxDist; // Far plane
        return result;
    }

    [[fragment]] FragmentOut fragment_main(VertexOut in [[stage_in]], constant SDFUniforms &uniforms [[buffer(0)]]) {
        // Setup ray from camera
        float2 uv = in.uv;

        float aspect = uniforms.resolution.x / uniforms.resolution.y;
        uv.x *= aspect;

        // Camera setup
        float3 ro = uniforms.cameraPos;
        float3 lookAt = float3(0.0, 0.0, 0.0);

        // Calculate camera matrix
        float3 forward = normalize(lookAt - ro);
        float3 right = normalize(cross(float3(0, 1, 0), forward));
        float3 up = cross(forward, right);

        // Ray direction
        float fov = 1.0;
        float3 rd = normalize(forward * fov + right * uv.x + up * uv.y);

        // Render
        RayMarchResult result = rayMarch(ro, rd, uniforms.time);

        // Gamma correction
        float3 color = pow(result.color, 1.0 / 2.2);

        FragmentOut out;

        // Calculate depth value
        float depthValue = 1.0;
        if (result.distance < 50.0) { // If we hit something
            // Simple linear depth mapping
            float near = 0.1;
            float far = 20.0;

            // Linear depth in [0,1]
            float linearDepth = (result.distance - near) / (far - near);
            depthValue = saturate(linearDepth);
        }

        // Output color or depth visualization based on flag
        if (uniforms.showDepth) {
            // Visualize depth as grayscale
            float depthVis = 1.0 - depthValue; // Invert so near is white, far is black
            out.color = float4(depthVis, depthVis, depthVis, 1.0);
        } else {
            out.color = float4(color, 1.0);
        }

        out.depth = depthValue;

        return out;
    }

} // namespace SDFShader
