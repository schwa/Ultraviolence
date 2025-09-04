#import <metal_stdlib>

using namespace metal;

namespace GameOfLifeShader {

    // Main Game of Life compute kernel
    kernel void updateGrid(
        texture2d<float, access::read> currentState [[texture(0)]],
        texture2d<float, access::write> nextState [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        // Get texture dimensions
        uint2 textureSize = uint2(currentState.get_width(), currentState.get_height());

        // Boundary check
        if (gid.x >= textureSize.x || gid.y >= textureSize.y) {
            return;
        }

        // Count living neighbors (8-connected with toroidal wrapping)
        int liveNeighbors = 0;

        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                if (dx == 0 && dy == 0)
                    continue; // Skip self

                // Wrap around edges for toroidal topology
                int2 neighborPos = int2(gid) + int2(dx, dy);
                neighborPos.x = (neighborPos.x + int(textureSize.x)) % int(textureSize.x);
                neighborPos.y = (neighborPos.y + int(textureSize.y)) % int(textureSize.y);

                float neighborValue = currentState.read(uint2(neighborPos)).r;
                if (neighborValue > 0.5) {
                    liveNeighbors++;
                }
            }
        }

        // Read current cell state
        float currentValue = currentState.read(gid).r;
        bool isAlive = (currentValue > 0.5);

        // Apply Conway's Game of Life rules
        bool nextAlive = false;
        if (isAlive) {
            // Living cell survives if it has 2 or 3 neighbors
            nextAlive = (liveNeighbors == 2 || liveNeighbors == 3);
        } else {
            // Dead cell becomes alive if it has exactly 3 neighbors
            nextAlive = (liveNeighbors == 3);
        }

        // Write result with some visual flair - fade out dead cells
        float outputValue = nextAlive ? 1.0 : 0.0;
        float4 color = float4(outputValue, outputValue * 0.9, outputValue * 0.7, 1.0);
        nextState.write(color, gid);
    }

    // Initialize with a glider pattern
    kernel void initializeGlider(
        texture2d<float, access::write> texture [[texture(0)]],
        uint2 gid [[thread_position_in_grid]],
        constant uint2 &offset [[buffer(0)]]
    ) {
        uint2 textureSize = uint2(texture.get_width(), texture.get_height());

        if (gid.x >= textureSize.x || gid.y >= textureSize.y) {
            return;
        }

        // Classic glider pattern:
        //   0 1 0
        //   0 0 1
        //   1 1 1

        int2 relPos = int2(gid) - int2(offset);
        bool isAlive = false;

        if ((relPos.x == 1 && relPos.y == 0) || // Top middle
            (relPos.x == 2 && relPos.y == 1) || // Middle right
            (relPos.x == 0 && relPos.y == 2) || // Bottom left
            (relPos.x == 1 && relPos.y == 2) || // Bottom middle
            (relPos.x == 2 && relPos.y == 2)) { // Bottom right
            isAlive = true;
        }

        float value = isAlive ? 1.0 : 0.0;
        float4 color = float4(value, value * 0.9, value * 0.7, 1.0);
        texture.write(color, gid);
    }

    // Initialize with random noise
    kernel void initializeRandom(
        texture2d<float, access::write> texture [[texture(0)]],
        uint2 gid [[thread_position_in_grid]],
        constant float &density [[buffer(0)]],
        constant uint &seed [[buffer(1)]]
    ) {
        uint2 textureSize = uint2(texture.get_width(), texture.get_height());

        if (gid.x >= textureSize.x || gid.y >= textureSize.y) {
            return;
        }

        // Simple pseudo-random number generation
        uint hash = gid.x + gid.y * textureSize.x + seed;
        hash = (hash ^ 61) ^ (hash >> 16);
        hash = hash + (hash << 3);
        hash = hash ^ (hash >> 4);
        hash = hash * 0x27d4eb2d;
        hash = hash ^ (hash >> 15);

        float random = float(hash) / float(0xFFFFFFFF);
        bool isAlive = random < density;

        float value = isAlive ? 1.0 : 0.0;
        float4 color = float4(value, value * 0.9, value * 0.7, 1.0);
        texture.write(color, gid);
    }

    // Clear the grid
    kernel void
    clearGrid(texture2d<float, access::write> texture [[texture(0)]], uint2 gid [[thread_position_in_grid]]) {
        uint2 textureSize = uint2(texture.get_width(), texture.get_height());

        if (gid.x >= textureSize.x || gid.y >= textureSize.y) {
            return;
        }

        texture.write(float4(0.0, 0.0, 0.0, 1.0), gid);
    }

    // Vertex shader for displaying the texture
    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 texCoords [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 texCoords;
    };

    vertex VertexOut displayVertex(VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.texCoords = in.texCoords;

        return out;
    }

    // Fragment shader for displaying the texture
    fragment float4 displayFragment(
        VertexOut in [[stage_in]],
        texture2d<float, access::sample> gameTexture [[texture(0)]],
        sampler textureSampler [[sampler(0)]]
    ) {
        float4 color = gameTexture.sample(textureSampler, in.texCoords);
        return color;
    }

} // namespace GameOfLifeShader