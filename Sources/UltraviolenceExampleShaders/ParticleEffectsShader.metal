#include <metal_stdlib>
#include "include/ParticleEffectsShader.h"
using namespace metal;

struct ParticleVertexOut {
    float4 position [[position]];
    float3 color;
    float pointSize [[point_size]];
    float alpha;
};

vertex ParticleVertexOut particleEffectsVertex(
    const device Particle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]],
    uint vertexID [[vertex_id]]
) {
    Particle particle = particles[vertexID];

    ParticleVertexOut out;

    // Transform position through view and projection
    float4 worldPos = float4(particle.position, 1.0);
    float4 viewPos = uniforms.viewMatrix * worldPos;
    out.position = uniforms.projectionMatrix * viewPos;

    // Pass through color with life-based alpha
    out.color = particle.color;
    out.alpha = particle.life; // Fade out as particle dies

    // Size based on life (particles can grow or shrink)
    float sizeMultiplier = particle.life * (2.0 - particle.life); // Peaks at 0.5 life
    out.pointSize = particle.size * uniforms.baseSize * sizeMultiplier;

    // Cull dead particles by making them tiny
    if (particle.life <= 0.0) {
        out.pointSize = 0.0;
    }

    return out;
}

fragment float4 particleEffectsFragment(
    ParticleVertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    // Calculate distance from center of point sprite
    float2 fromCenter = pointCoord - float2(0.5);
    float dist = length(fromCenter);

    // Smooth circular points
    if (dist > 0.5) {
        discard_fragment();
    }

    // Add some shading to make points look spherical
    float intensity = 1.0 - dist * 1.5;
    intensity = saturate(intensity);

    // Apply life-based fade
    intensity *= in.alpha;

    return float4(in.color * intensity, 1.0);
}


// Better random number generator with internal state
struct RandomGenerator {
    uint state;

    // Initialize with a good seed
    void seed(uint s, uint id, float time) {
        // Mix particle ID, time, and initial seed for good distribution
        state = s ^ (id * 2654435761u) ^ uint(time * 1000.0);
        // Warm up the generator
        next();
        next();
    }

    // Generate next random number using PCG algorithm
    uint next() {
        uint oldstate = state;
        state = oldstate * 747796405u + 2891336453u;
        uint word = ((oldstate >> ((oldstate >> 28u) + 4u)) ^ oldstate) * 277803737u;
        return (word >> 22u) ^ word;
    }

    // Get random float in [0, 1]
    float uniform() {
        return float(next()) / float(0xFFFFFFFF);
    }

    // Get random float in [min, max]
    float range(float min, float max) {
        return min + uniform() * (max - min);
    }

    // Get random float3 in [-1, 1]
    float3 direction() {
        return float3(
            range(-1.0, 1.0),
            range(-1.0, 1.0),
            range(-1.0, 1.0)
        );
    }
};

// Compute kernel for updating particles
kernel void updateParticles(
    device Particle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]],
    device ParticleEmitterParams& emitter [[buffer(2)]],
    constant uint& particleCount [[buffer(3)]],
    uint id [[thread_position_in_grid]]
) {
    if (id >= particleCount) return; // Bounds check

    device Particle& particle = particles[id];
    float dt = 1.0 / 60.0; // 60 FPS

    // Initialize RNG for this particle
    RandomGenerator rng;
    rng.seed(id, id, uniforms.time);

    // Update living particles
    if (particle.life > 0.0) {
        // Apply physics
        particle.velocity += uniforms.gravity * dt;
        particle.velocity *= 0.99; // Drag
        particle.position += particle.velocity * dt;

        // Update life
        particle.life -= dt * 0.3; // ~3 second lifetime
        particle.life = max(particle.life, 0.0);
    }
    // Try to emit new particles from dead ones
    else {
        // Simple emission rate check
        float particlesPerFrame = emitter.emissionRate / 60.0;
        float emitProbability = particlesPerFrame / float(particleCount);

        // Each dead particle has a chance to emit
        if (rng.uniform() < emitProbability) {
            // Reset particle
            particle.life = 1.0;
            particle.size = rng.range(0.5, 1.5);

            switch (emitter.emitterType) {
                case 0: { // Fountain
                    // Start at emitter position with small random offset
                    particle.position = emitter.position;
                    particle.position.x += rng.range(-0.1, 0.1);
                    particle.position.z += rng.range(-0.1, 0.1);

                    // Upward velocity with random spread
                    float angle = rng.uniform() * 6.28318;
                    float spread = rng.range(0.0, 0.3);
                    float speed = rng.range(6.0, 8.0);

                    particle.velocity = float3(
                        cos(angle) * spread * speed,
                        speed,
                        sin(angle) * spread * speed
                    );

                    // Blue-ish color with variation
                    particle.color = float3(
                        rng.range(0.1, 0.3),
                        rng.range(0.3, 0.5),
                        rng.range(0.7, 1.0)
                    );
                    break;
                }

                case 1: { // Explosion
                    particle.position = emitter.position;
                    float3 dir = normalize(rng.direction());
                    float speed = rng.range(3.0, 10.0);
                    particle.velocity = dir * speed;
                    particle.color = float3(
                        1.0,
                        rng.range(0.3, 0.7),
                        0.0
                    );
                    break;
                }

                case 2: { // Rain
                    particle.position = emitter.position;
                    particle.position.x += rng.range(-5.0, 5.0);
                    particle.position.z += rng.range(-5.0, 5.0);
                    particle.velocity = float3(
                        rng.range(-0.5, 0.5),
                        rng.range(-8.0, -10.0),
                        rng.range(-0.5, 0.5)
                    );
                    particle.color = float3(0.5, 0.5, 1.0);
                    break;
                }

                case 3: { // Fireworks
                    particle.position = emitter.position;
                    particle.velocity = float3(
                        rng.range(-1.0, 1.0),
                        rng.range(8.0, 12.0),
                        rng.range(-1.0, 1.0)
                    );
                    // Rainbow colors
                    float hue = rng.uniform();
                    if (hue < 0.33) {
                        particle.color = float3(1, hue * 3, 0);
                    } else if (hue < 0.66) {
                        particle.color = float3(1 - (hue - 0.33) * 3, 1, 0);
                    } else {
                        particle.color = float3(0, 1, (hue - 0.66) * 3);
                    }
                    break;
                }

                case 4: { // Tornado
                    float angle = uniforms.time * 10.0 + rng.uniform() * 6.28318;
                    float radius = rng.range(0.5, 2.0);
                    particle.position = emitter.position + float3(
                        cos(angle) * radius,
                        rng.range(-1.0, 1.0),
                        sin(angle) * radius
                    );
                    particle.velocity = float3(
                        -sin(angle) * radius * 3.0,
                        rng.range(1.0, 3.0),
                        cos(angle) * radius * 3.0
                    );
                    particle.color = float3(0.8, 0.8, 0.8);
                    break;
                }

                case 5: { // Magic Portal - Doctor Strange style
                    // Create particles in a rotating ring with sparks
                    float portalRadius = 2.0;
                    float ringThickness = 0.2;

                    // Spawn particles along the ring circumference
                    float angle = rng.uniform() * 6.28318;
                    float radiusOffset = rng.range(-ringThickness, ringThickness);

                    // Position on the ring
                    particle.position = emitter.position + float3(
                        cos(angle) * (portalRadius + radiusOffset),
                        sin(angle) * (portalRadius + radiusOffset),
                        rng.range(-0.1, 0.1)  // Slight z variation
                    );

                    // Velocity - particles spin around the ring and emit sparks
                    float spinSpeed = 8.0;
                    float3 tangent = float3(-sin(angle), cos(angle), 0) * spinSpeed;

                    // Add some outward/inward motion for spark effect
                    float3 radial = float3(cos(angle), sin(angle), 0) * rng.range(-1.0, 2.0);

                    // Small random perturbation
                    float3 random = rng.direction() * 0.5;

                    particle.velocity = tangent + radial + random;

                    // Orange/gold color like Doctor Strange portals
                    float heat = rng.range(0.7, 1.0);
                    particle.color = float3(
                        1.0,
                        heat * 0.6,
                        heat * 0.1
                    );

                    // Vary particle size for sparkle effect
                    particle.size = rng.range(0.3, 1.2);

                    // Shorter life for more dynamic effect
                    particle.life = rng.range(0.3, 0.8);
                    break;
                }
            }
        }
    }
}