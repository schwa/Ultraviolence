import Foundation
import simd

extension TrivialMesh {
    static func box() -> TrivialMesh {
        // Unit cube vertices (-0.5 to 0.5 on each axis)
        let positions: [SIMD3<Float>] = [
            // Front face (z = 0.5)
            [-0.5, -0.5, 0.5], // 0: bottom-left
            [ 0.5, -0.5, 0.5], // 1: bottom-right
            [ 0.5, 0.5, 0.5], // 2: top-right
            [-0.5, 0.5, 0.5], // 3: top-left

            // Back face (z = -0.5)
            [-0.5, -0.5, -0.5], // 4: bottom-left
            [ 0.5, -0.5, -0.5], // 5: bottom-right
            [ 0.5, 0.5, -0.5], // 6: top-right
            [-0.5, 0.5, -0.5], // 7: top-left

            // Top face (y = 0.5)
            [-0.5, 0.5, 0.5], // 8: front-left
            [ 0.5, 0.5, 0.5], // 9: front-right
            [ 0.5, 0.5, -0.5], // 10: back-right
            [-0.5, 0.5, -0.5], // 11: back-left

            // Bottom face (y = -0.5)
            [-0.5, -0.5, 0.5], // 12: front-left
            [ 0.5, -0.5, 0.5], // 13: front-right
            [ 0.5, -0.5, -0.5], // 14: back-right
            [-0.5, -0.5, -0.5], // 15: back-left

            // Right face (x = 0.5)
            [ 0.5, -0.5, 0.5], // 16: front-bottom
            [ 0.5, -0.5, -0.5], // 17: back-bottom
            [ 0.5, 0.5, -0.5], // 18: back-top
            [ 0.5, 0.5, 0.5], // 19: front-top

            // Left face (x = -0.5)
            [-0.5, -0.5, 0.5], // 20: front-bottom
            [-0.5, -0.5, -0.5], // 21: back-bottom
            [-0.5, 0.5, -0.5], // 22: back-top
            [-0.5, 0.5, 0.5] // 23: front-top
        ]

        let textureCoordinates: [SIMD2<Float>] = [
            // Front face
            [0, 1], [1, 1], [1, 0], [0, 0],
            // Back face
            [1, 1], [0, 1], [0, 0], [1, 0],
            // Top face
            [0, 0], [1, 0], [1, 1], [0, 1],
            // Bottom face
            [0, 1], [1, 1], [1, 0], [0, 0],
            // Right face
            [0, 1], [1, 1], [1, 0], [0, 0],
            // Left face
            [1, 1], [0, 1], [0, 0], [1, 0]
        ]

        let normals: [SIMD3<Float>] = [
            // Front face
            [0, 0, 1], [0, 0, 1], [0, 0, 1], [0, 0, 1],
            // Back face
            [0, 0, -1], [0, 0, -1], [0, 0, -1], [0, 0, -1],
            // Top face
            [0, 1, 0], [0, 1, 0], [0, 1, 0], [0, 1, 0],
            // Bottom face
            [0, -1, 0], [0, -1, 0], [0, -1, 0], [0, -1, 0],
            // Right face
            [1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0],
            // Left face
            [-1, 0, 0], [-1, 0, 0], [-1, 0, 0], [-1, 0, 0]
        ]

        // Counter-clockwise winding order for front faces
        let indices: [Int] = [
            // Front face
            0, 1, 2, 0, 2, 3,
            // Back face
            4, 6, 5, 4, 7, 6,
            // Top face
            8, 9, 10, 8, 10, 11,
            // Bottom face
            12, 14, 13, 12, 15, 14,
            // Right face
            16, 17, 18, 16, 18, 19,
            // Left face
            20, 22, 21, 20, 23, 22
        ]

        return TrivialMesh(
            label: "Box",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func tetrahedron() -> TrivialMesh {
        // Regular tetrahedron centered at origin
        // Height chosen so it fits in unit cube (-0.5 to 0.5)
        let a: Float = 0.5 // Half edge length for unit size
        let h: Float = sqrt(2.0 / 3.0) * a // Height from base to top
        let r: Float = sqrt(3.0) / 3.0 * a // Radius from center of base to vertex

        // 4 faces x 3 vertices = 12 vertices (duplicated for proper normals/UVs)
        let positions: [SIMD3<Float>] = [
            // Bottom face (looking up)
            [0, -h / 2, r],           // 0: front vertex
            [r * cos(7 * Float.pi / 6), -h / 2, r * sin(7 * Float.pi / 6)], // 1: back-left
            [r * cos(11 * Float.pi / 6), -h / 2, r * sin(11 * Float.pi / 6)], // 2: back-right

            // Front face
            [0, -h / 2, r],           // 3: bottom-front
            [r * cos(11 * Float.pi / 6), -h / 2, r * sin(11 * Float.pi / 6)], // 4: bottom-right
            [0, h / 2, 0],            // 5: top

            // Right face
            [r * cos(11 * Float.pi / 6), -h / 2, r * sin(11 * Float.pi / 6)], // 6: bottom-right
            [r * cos(7 * Float.pi / 6), -h / 2, r * sin(7 * Float.pi / 6)], // 7: bottom-left
            [0, h / 2, 0],            // 8: top

            // Left face
            [r * cos(7 * Float.pi / 6), -h / 2, r * sin(7 * Float.pi / 6)], // 9: bottom-left
            [0, -h / 2, r],           // 10: bottom-front
            [0, h / 2, 0]            // 11: top
        ]

        // UV coordinates for each face
        let textureCoordinates: [SIMD2<Float>] = [
            // Bottom face
            [0.5, 1], [0, 0], [1, 0],
            // Front face
            [0, 0], [1, 0], [0.5, 1],
            // Right face
            [0, 0], [1, 0], [0.5, 1],
            // Left face
            [0, 0], [1, 0], [0.5, 1]
        ]

        // Calculate normals for each face
        let bottomNormal = normalize(cross(positions[1] - positions[0], positions[2] - positions[0]))
        let frontNormal = normalize(cross(positions[4] - positions[3], positions[5] - positions[3]))
        let rightNormal = normalize(cross(positions[7] - positions[6], positions[8] - positions[6]))
        let leftNormal = normalize(cross(positions[10] - positions[9], positions[11] - positions[9]))

        let normals: [SIMD3<Float>] = [
            // Bottom face (pointing down)
            bottomNormal, bottomNormal, bottomNormal,
            // Front face
            frontNormal, frontNormal, frontNormal,
            // Right face
            rightNormal, rightNormal, rightNormal,
            // Left face
            leftNormal, leftNormal, leftNormal
        ]

        let indices: [Int] = [
            // Bottom face (viewed from below, CCW)
            0, 2, 1,
            // Front face
            3, 4, 5,
            // Right face
            6, 7, 8,
            // Left face
            9, 10, 11
        ]

        return TrivialMesh(
            label: "Tetrahedron",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func octahedron() -> TrivialMesh {
        // Regular octahedron centered at origin
        let r: Float = 0.5 // Distance from center to vertices

        // 8 faces x 3 vertices = 24 vertices (duplicated for proper normals/UVs)
        let positions: [SIMD3<Float>] = [
            // Top pyramid - 4 faces
            // Front face
            [0, r, 0],     // 0: top
            [-r, 0, 0],    // 1: left
            [0, 0, r],     // 2: front

            // Right face
            [0, r, 0],     // 3: top
            [0, 0, r],     // 4: front
            [r, 0, 0],     // 5: right

            // Back face
            [0, r, 0],     // 6: top
            [r, 0, 0],     // 7: right
            [0, 0, -r],    // 8: back

            // Left face
            [0, r, 0],     // 9: top
            [0, 0, -r],    // 10: back
            [-r, 0, 0],    // 11: left

            // Bottom pyramid - 4 faces
            // Front face
            [0, -r, 0],    // 12: bottom
            [0, 0, r],     // 13: front
            [-r, 0, 0],    // 14: left

            // Right face
            [0, -r, 0],    // 15: bottom
            [r, 0, 0],     // 16: right
            [0, 0, r],     // 17: front

            // Back face
            [0, -r, 0],    // 18: bottom
            [0, 0, -r],    // 19: back
            [r, 0, 0],     // 20: right

            // Left face
            [0, -r, 0],    // 21: bottom
            [-r, 0, 0],    // 22: left
            [0, 0, -r]    // 23: back
        ]

        // UV coordinates for each triangular face
        let textureCoordinates: [SIMD2<Float>] = [
            // Top pyramid faces
            [0.5, 1], [0, 0], [1, 0],  // Front
            [0.5, 1], [0, 0], [1, 0],  // Right
            [0.5, 1], [0, 0], [1, 0],  // Back
            [0.5, 1], [0, 0], [1, 0],  // Left
            // Bottom pyramid faces
            [0.5, 0], [1, 1], [0, 1],  // Front
            [0.5, 0], [1, 1], [0, 1],  // Right
            [0.5, 0], [1, 1], [0, 1],  // Back
            [0.5, 0], [1, 1], [0, 1]  // Left
        ]

        // Calculate normals for each face
        var normals: [SIMD3<Float>] = []
        for i in 0..<8 {
            let baseIdx = i * 3
            let v0 = positions[baseIdx]
            let v1 = positions[baseIdx + 1]
            let v2 = positions[baseIdx + 2]
            let normal = normalize(cross(v1 - v0, v2 - v0))
            normals.append(contentsOf: [normal, normal, normal])
        }

        let indices: [Int] = Array(0..<24)

        return TrivialMesh(
            label: "Octahedron",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func icosahedron() -> TrivialMesh {
        // Regular icosahedron - 20 triangular faces, 12 vertices
        let phi = Float((1.0 + sqrt(5.0)) / 2.0) // Golden ratio
        let scale: Float = 0.5 / sqrt(phi * phi + 1) // Scale to fit in unit cube

        // The 12 vertices of an icosahedron
        let v: [SIMD3<Float>] = [
            // Rectangle on XY plane
            [-1, phi, 0],
            [ 1, phi, 0],
            [-1, -phi, 0],
            [ 1, -phi, 0],
            // Rectangle on YZ plane
            [0, -1, phi],
            [0, 1, phi],
            [0, -1, -phi],
            [0, 1, -phi],
            // Rectangle on XZ plane
            [ phi, 0, -1],
            [ phi, 0, 1],
            [-phi, 0, -1],
            [-phi, 0, 1]
        ].map { $0 * scale }

        // 20 triangular faces (each face gets its own vertices for proper normals)
        let faceIndices = [
            // 5 faces around top vertex
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
            // 5 adjacent faces
            [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            // 5 adjacent faces
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
            // 5 faces around bottom vertex
            [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
        ]

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        for (faceIndex, face) in faceIndices.enumerated() {
            let v0 = v[face[0]]
            let v1 = v[face[1]]
            let v2 = v[face[2]]

            // Calculate face normal
            let normal = normalize(cross(v1 - v0, v2 - v0))

            // Add vertices for this face
            positions.append(contentsOf: [v0, v1, v2])
            normals.append(contentsOf: [normal, normal, normal])

            // Simple UV mapping for triangular faces
            textureCoordinates.append(contentsOf: [
                [0.5, 1], [0, 0], [1, 0]
            ])

            // Add indices
            let baseIndex = faceIndex * 3
            indices.append(contentsOf: [baseIndex, baseIndex + 1, baseIndex + 2])
        }

        return TrivialMesh(
            label: "Icosahedron",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func dodecahedron() -> TrivialMesh {
        // Regular dodecahedron - 12 pentagonal faces, 20 vertices
        let phi = Float((1.0 + sqrt(5.0)) / 2.0) // Golden ratio
        let scale: Float = 0.5 / sqrt(3.0) // Scale to fit in unit cube

        // The 20 vertices of a dodecahedron
        let v: [SIMD3<Float>] = [
            // Cube vertices
            [-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1],
            [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1],
            // Rectangle on XY plane
            [0, -1 / phi, -phi], [0, 1 / phi, -phi], [0, 1 / phi, phi], [0, -1 / phi, phi],
            // Rectangle on YZ plane
            [-1 / phi, -phi, 0], [1 / phi, -phi, 0], [1 / phi, phi, 0], [-1 / phi, phi, 0],
            // Rectangle on XZ plane
            [-phi, 0, -1 / phi], [-phi, 0, 1 / phi], [phi, 0, 1 / phi], [phi, 0, -1 / phi]
        ].map { $0 * scale }

        // 12 pentagonal faces (each split into 3 triangles from center)
        let faceIndices = [
            [0, 8, 9, 3, 16],   // Front face
            [1, 19, 2, 9, 8],   // Right-front face
            [4, 17, 7, 10, 11], // Back face
            [5, 11, 10, 6, 18], // Right-back face
            [0, 16, 17, 4, 12], // Bottom-left face
            [1, 13, 5, 18, 19], // Bottom-right face
            [2, 19, 18, 6, 14], // Top-right face
            [3, 15, 7, 17, 16], // Top-left face
            [0, 12, 13, 1, 8],  // Bottom face
            [2, 14, 15, 3, 9],  // Top face
            [4, 11, 5, 13, 12], // Left-back face
            [6, 10, 7, 15, 14] // Right-top face
        ]

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        for face in faceIndices {
            // Calculate face center
            var center = SIMD3<Float>(0, 0, 0)
            for vertexIndex in face {
                center += v[vertexIndex]
            }
            center /= Float(face.count)

            // Calculate face normal using first two edges
            let v0 = v[face[0]]
            let v1 = v[face[1]]
            let normal = normalize(cross(v1 - v0, center - v0))

            // Add center vertex
            let centerIndex = positions.count
            positions.append(center)
            normals.append(normal)
            textureCoordinates.append([0.5, 0.5])

            // Add pentagon vertices and create triangles
            for i in 0..<5 {
                let vertex = v[face[i]]
                positions.append(vertex)
                normals.append(normal)

                // UV coordinates for pentagon vertices
                let angle = Float(i) * 2.0 * Float.pi / 5.0
                let u = (cos(angle) + 1) * 0.5
                let v = (sin(angle) + 1) * 0.5
                textureCoordinates.append([u, v])
            }

            // Create 5 triangles from center to each edge
            for i in 0..<5 {
                let nextIndex = (i + 1) % 5
                indices.append(contentsOf: [
                    centerIndex,
                    centerIndex + 1 + i,
                    centerIndex + 1 + nextIndex
                ])
            }
        }

        return TrivialMesh(
            label: "Dodecahedron",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func sphere(latitudeSegments: Int = 16, longitudeSegments: Int = 32) -> TrivialMesh {
        // UV sphere - easiest to implement
        let radius: Float = 0.5

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        // Generate vertices
        for lat in 0...latitudeSegments {
            let theta = Float(lat) * Float.pi / Float(latitudeSegments)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)

            for lon in 0...longitudeSegments {
                let phi = Float(lon) * 2.0 * Float.pi / Float(longitudeSegments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                let x = cosPhi * sinTheta
                let y = cosTheta
                let z = sinPhi * sinTheta

                let position = SIMD3<Float>(x, y, z) * radius
                positions.append(position)

                // Normal is just the normalized position for a sphere centered at origin
                normals.append(SIMD3<Float>(x, y, z))

                // UV coordinates
                let u = Float(lon) / Float(longitudeSegments)
                let v = Float(lat) / Float(latitudeSegments)
                textureCoordinates.append([u, v])
            }
        }

        // Generate indices
        for lat in 0..<latitudeSegments {
            for lon in 0..<longitudeSegments {
                let first = lat * (longitudeSegments + 1) + lon
                let second = first + longitudeSegments + 1

                // Two triangles per quad
                indices.append(contentsOf: [
                    first, second, first + 1,
                    second, second + 1, first + 1
                ])
            }
        }

        return TrivialMesh(
            label: "Sphere",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func torus(majorSegments: Int = 32, minorSegments: Int = 16, majorRadius: Float = 0.3, minorRadius: Float = 0.15) -> TrivialMesh {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        // Generate vertices
        for i in 0...majorSegments {
            let u = Float(i) / Float(majorSegments)
            let theta = u * 2.0 * Float.pi

            for j in 0...minorSegments {
                let v = Float(j) / Float(minorSegments)
                let phi = v * 2.0 * Float.pi

                // Position on the tube circle
                let x = (majorRadius + minorRadius * cos(phi)) * cos(theta)
                let y = minorRadius * sin(phi)
                let z = (majorRadius + minorRadius * cos(phi)) * sin(theta)

                positions.append([x, y, z])

                // Normal (pointing outward from the tube surface)
                let centerX = majorRadius * cos(theta)
                let centerZ = majorRadius * sin(theta)
                let normal = normalize(SIMD3<Float>(x - centerX, y, z - centerZ))
                normals.append(normal)

                textureCoordinates.append([u, v])
            }
        }

        // Generate indices
        for i in 0..<majorSegments {
            for j in 0..<minorSegments {
                let a = i * (minorSegments + 1) + j
                let b = a + minorSegments + 1
                let c = a + 1
                let d = b + 1

                indices.append(contentsOf: [
                    a, b, c,
                    b, d, c
                ])
            }
        }

        return TrivialMesh(
            label: "Torus",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func capsule(segments: Int = 32, rings: Int = 8, height: Float = 0.5, radius: Float = 0.25) -> TrivialMesh {
        // Capsule = cylinder with hemisphere caps
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        let halfHeight = height * 0.5

        // Generate top hemisphere
        for ring in 0...rings / 2 {
            let theta = Float(ring) * Float.pi / Float(rings)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            let y = halfHeight + radius * cosTheta

            for segment in 0...segments {
                let phi = Float(segment) * 2.0 * Float.pi / Float(segments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                let x = radius * sinTheta * cosPhi
                let z = radius * sinTheta * sinPhi

                positions.append([x, y, z])
                normals.append(normalize([sinTheta * cosPhi, cosTheta, sinTheta * sinPhi]))

                let u = Float(segment) / Float(segments)
                let v = Float(ring) / Float(rings + 2)
                textureCoordinates.append([u, v])
            }
        }

        // Generate cylinder middle
        for i in 0...1 {
            let y = halfHeight - Float(i) * height

            for segment in 0...segments {
                let phi = Float(segment) * 2.0 * Float.pi / Float(segments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                let x = radius * cosPhi
                let z = radius * sinPhi

                positions.append([x, y, z])
                normals.append(normalize([cosPhi, 0, sinPhi]))

                let u = Float(segment) / Float(segments)
                let v = (Float(rings / 2) + Float(i) * 2) / Float(rings + 2)
                textureCoordinates.append([u, v])
            }
        }

        // Generate bottom hemisphere
        for ring in rings / 2...rings {
            let theta = Float(ring) * Float.pi / Float(rings)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            let y = -halfHeight + radius * cosTheta

            for segment in 0...segments {
                let phi = Float(segment) * 2.0 * Float.pi / Float(segments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                let x = radius * sinTheta * cosPhi
                let z = radius * sinTheta * sinPhi

                positions.append([x, y, z])
                normals.append(normalize([sinTheta * cosPhi, cosTheta, sinTheta * sinPhi]))

                let u = Float(segment) / Float(segments)
                let v = (Float(ring) + 2) / Float(rings + 2)
                textureCoordinates.append([u, v])
            }
        }

        // Generate indices
        let totalRings = rings + 2 // hemispheres + cylinder
        for ring in 0..<totalRings {
            for segment in 0..<segments {
                let a = ring * (segments + 1) + segment
                let b = a + segments + 1
                let c = a + 1
                let d = b + 1

                indices.append(contentsOf: [
                    a, b, c,
                    b, d, c
                ])
            }
        }

        return TrivialMesh(
            label: "Capsule",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func icoSphere(subdivisions: Int = 2) -> TrivialMesh {
        // Create sphere by subdividing an icosahedron
        let t = Float((1.0 + sqrt(5.0)) / 2.0)

        // Initial icosahedron vertices (normalized)
        var vertices: [SIMD3<Float>] = [
            normalize([-1, t, 0]), normalize([1, t, 0]), normalize([-1, -t, 0]), normalize([1, -t, 0]),
            normalize([0, -1, t]), normalize([0, 1, t]), normalize([0, -1, -t]), normalize([0, 1, -t]),
            normalize([t, 0, -1]), normalize([t, 0, 1]), normalize([-t, 0, -1]), normalize([-t, 0, 1])
        ]

        // Initial icosahedron faces
        var faces: [[Int]] = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
            [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
            [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
        ]

        // Subdivision
        for _ in 0..<subdivisions {
            var newFaces: [[Int]] = []
            var midpointCache: [String: Int] = [:]

            func getMidpoint(_ v1: Int, _ v2: Int) -> Int {
                let key = "\(min(v1, v2))-\(max(v1, v2))"
                if let cached = midpointCache[key] {
                    return cached
                }

                let mid = normalize((vertices[v1] + vertices[v2]) / 2.0)
                vertices.append(mid)
                let index = vertices.count - 1
                midpointCache[key] = index
                return index
            }

            for face in faces {
                let v1 = face[0]
                let v2 = face[1]
                let v3 = face[2]

                let a = getMidpoint(v1, v2)
                let b = getMidpoint(v2, v3)
                let c = getMidpoint(v3, v1)

                newFaces.append([v1, a, c])
                newFaces.append([v2, b, a])
                newFaces.append([v3, c, b])
                newFaces.append([a, b, c])
            }

            faces = newFaces
        }

        // Scale vertices to radius 0.5
        vertices = vertices.map { $0 * 0.5 }

        // Build mesh data
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        for (faceIndex, face) in faces.enumerated() {
            for vertexIndex in face {
                let position = vertices[vertexIndex]
                positions.append(position)
                normals.append(normalize(position))

                // Calculate UV coordinates from spherical coordinates
                let normal = normalize(position)
                let u = 0.5 + atan2(normal.z, normal.x) / (2.0 * Float.pi)
                let v = 0.5 - asin(normal.y) / Float.pi
                textureCoordinates.append([u, v])

                indices.append(faceIndex * 3 + positions.count - 1 - (faceIndex * 3))
            }
        }

        return TrivialMesh(
            label: "IcoSphere",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func cubeSphere(subdivisions: Int = 4) -> TrivialMesh {
        // Create sphere by normalizing a subdivided cube
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        // Generate each face of the cube
        let faces: [(normal: SIMD3<Float>, up: SIMD3<Float>, right: SIMD3<Float>)] = [
            (normal: [0, 0, 1], up: [0, 1, 0], right: [1, 0, 0]),    // Front
            (normal: [0, 0, -1], up: [0, 1, 0], right: [-1, 0, 0]),  // Back
            (normal: [1, 0, 0], up: [0, 1, 0], right: [0, 0, -1]),   // Right
            (normal: [-1, 0, 0], up: [0, 1, 0], right: [0, 0, 1]),   // Left
            (normal: [0, 1, 0], up: [0, 0, -1], right: [1, 0, 0]),   // Top
            (normal: [0, -1, 0], up: [0, 0, 1], right: [1, 0, 0])    // Bottom
        ]

        for face in faces {
            let baseIndex = positions.count

            // Generate vertices for this face
            for y in 0...subdivisions {
                for x in 0...subdivisions {
                    // Calculate position on cube face (-0.5 to 0.5)
                    let fx = Float(x) / Float(subdivisions) - 0.5
                    let fy = Float(y) / Float(subdivisions) - 0.5

                    // Position on cube face
                    let cubePos = face.normal * 0.5 + face.right * fx + face.up * fy

                    // Normalize to sphere surface and scale to radius 0.5
                    let spherePos = normalize(cubePos) * 0.5
                    positions.append(spherePos)
                    normals.append(normalize(spherePos))

                    // UV coordinates
                    let u = Float(x) / Float(subdivisions)
                    let v = Float(y) / Float(subdivisions)
                    textureCoordinates.append([u, v])
                }
            }

            // Generate indices for this face
            for y in 0..<subdivisions {
                for x in 0..<subdivisions {
                    let i0 = baseIndex + y * (subdivisions + 1) + x
                    let i1 = i0 + 1
                    let i2 = i0 + subdivisions + 1
                    let i3 = i2 + 1

                    // Two triangles per quad
                    indices.append(contentsOf: [i0, i1, i2])
                    indices.append(contentsOf: [i1, i3, i2])
                }
            }
        }

        return TrivialMesh(
            label: "CubeSphere",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func cone(segments: Int = 32, height: Float = 1.0, radius: Float = 0.5, capped: Bool = false) -> TrivialMesh {
        // Cone with optional base cap
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        let halfHeight = height * 0.5

        // Apex vertex (duplicated for each face for proper normals)
        let apex = SIMD3<Float>(0, halfHeight, 0)

        // Generate cone sides
        for i in 0..<segments {
            let angle1 = Float(i) * 2.0 * Float.pi / Float(segments)
            let angle2 = Float(i + 1) * 2.0 * Float.pi / Float(segments)

            let x1 = radius * cos(angle1)
            let z1 = radius * sin(angle1)
            let x2 = radius * cos(angle2)
            let z2 = radius * sin(angle2)

            let base1 = SIMD3<Float>(x1, -halfHeight, z1)
            let base2 = SIMD3<Float>(x2, -halfHeight, z2)

            // Calculate normal for this face
            let edge1 = base1 - apex
            let edge2 = base2 - apex
            let faceNormal = normalize(cross(edge1, edge2))

            // Add triangle for this segment
            let baseIndex = positions.count
            positions.append(contentsOf: [apex, base1, base2])
            normals.append(contentsOf: [faceNormal, faceNormal, faceNormal])

            // UV coordinates
            textureCoordinates.append(contentsOf: [
                [0.5, 1], // apex
                [Float(i) / Float(segments), 0], // base1
                [Float(i + 1) / Float(segments), 0] // base2
            ])

            indices.append(contentsOf: [baseIndex, baseIndex + 1, baseIndex + 2])
        }

        // Add base cap if requested
        if capped {
            let baseCenterIndex = positions.count
            positions.append([0, -halfHeight, 0])
            normals.append([0, -1, 0])
            textureCoordinates.append([0.5, 0.5])

            for i in 0..<segments {
                let angle1 = Float(i) * 2.0 * Float.pi / Float(segments)
                let angle2 = Float(i + 1) * 2.0 * Float.pi / Float(segments)

                let x1 = radius * cos(angle1)
                let z1 = radius * sin(angle1)
                let x2 = radius * cos(angle2)
                let z2 = radius * sin(angle2)

                let v1Index = positions.count
                positions.append([x1, -halfHeight, z1])
                positions.append([x2, -halfHeight, z2])
                normals.append(contentsOf: [[0, -1, 0], [0, -1, 0]])

                // UV for base
                let u1 = (cos(angle1) + 1) * 0.5
                let v1 = (sin(angle1) + 1) * 0.5
                let u2 = (cos(angle2) + 1) * 0.5
                let v2 = (sin(angle2) + 1) * 0.5
                textureCoordinates.append(contentsOf: [[u1, v1], [u2, v2]])

                // Triangle from center to edge (clockwise for bottom face)
                indices.append(contentsOf: [baseCenterIndex, v1Index + 1, v1Index])
            }
        }

        return TrivialMesh(
            label: capped ? "Capped Cone" : "Cone",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func hemisphere(segments: Int = 32, rings: Int = 16) -> TrivialMesh {
        // Half sphere
        let radius: Float = 0.5

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var indices: [Int] = []

        // Generate vertices (only top half)
        for ring in 0...rings {
            let theta = Float(ring) * (Float.pi / 2.0) / Float(rings) // Only go from 0 to π/2
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)

            for segment in 0...segments {
                let phi = Float(segment) * 2.0 * Float.pi / Float(segments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                let x = cosPhi * sinTheta
                let y = cosTheta // y is up
                let z = sinPhi * sinTheta

                positions.append(SIMD3<Float>(x, y, z) * radius)
                normals.append(SIMD3<Float>(x, y, z))

                let u = Float(segment) / Float(segments)
                let v = Float(ring) / Float(rings)
                textureCoordinates.append([u, v])
            }
        }

        // Generate indices
        for ring in 0..<rings {
            for segment in 0..<segments {
                let first = ring * (segments + 1) + segment
                let second = first + segments + 1

                indices.append(contentsOf: [
                    first, second, first + 1,
                    second, second + 1, first + 1
                ])
            }
        }

        // Add base circle
        let baseCenterIndex = positions.count
        positions.append([0, 0, 0])
        normals.append([0, -1, 0])
        textureCoordinates.append([0.5, 0.5])

        // Base ring vertices
        let baseStartIndex = positions.count
        for segment in 0...segments {
            let phi = Float(segment) * 2.0 * Float.pi / Float(segments)
            let x = cos(phi) * radius
            let z = sin(phi) * radius

            positions.append([x, 0, z])
            normals.append([0, -1, 0])

            let u = (cos(phi) + 1) * 0.5
            let v = (sin(phi) + 1) * 0.5
            textureCoordinates.append([u, v])
        }

        // Base triangles
        for segment in 0..<segments {
            indices.append(contentsOf: [
                baseCenterIndex,
                baseStartIndex + segment + 1,
                baseStartIndex + segment
            ])
        }

        return TrivialMesh(
            label: "Hemisphere",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func circle(segments: Int = 32) -> TrivialMesh {
        // Circle on XY plane centered at origin
        let radius: Float = 0.5

        // Center vertex plus vertices around the perimeter
        var positions: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [Int] = []

        // Center vertex
        positions.append([0, 0, 0])
        textureCoordinates.append([0.5, 0.5])
        normals.append([0, 0, 1])

        // Generate vertices around the perimeter
        for i in 0..<segments {
            let angle = Float(i) * 2.0 * Float.pi / Float(segments)
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            positions.append([x, y, 0])

            // UV coordinates
            let u = (cos(angle) + 1) * 0.5
            let v = (sin(angle) + 1) * 0.5
            textureCoordinates.append([u, v])
            normals.append([0, 0, 1])
        }

        // Create triangles from center to each edge
        for i in 0..<segments {
            let nextIndex = (i + 1) % segments + 1
            indices.append(contentsOf: [0, i + 1, nextIndex])
        }

        return TrivialMesh(
            label: "Circle",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func quad() -> TrivialMesh {
        // Square on XY plane centered at origin
        let positions: [SIMD3<Float>] = [
            [-0.5, -0.5, 0], // 0: bottom-left
            [ 0.5, -0.5, 0], // 1: bottom-right
            [ 0.5, 0.5, 0], // 2: top-right
            [-0.5, 0.5, 0] // 3: top-left
        ]

        let textureCoordinates: [SIMD2<Float>] = [
            [0, 0], // bottom-left
            [1, 0], // bottom-right
            [1, 1], // top-right
            [0, 1] // top-left
        ]

        let normals: [SIMD3<Float>] = [
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 1]
        ]

        // Two triangles to form a quad
        let indices: [Int] = [
            0, 1, 2,  // First triangle
            0, 2, 3  // Second triangle
        ]

        return TrivialMesh(
            label: "Quad",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }

    static func triangle() -> TrivialMesh {
        // Equilateral triangle on XY plane centered at origin
        let height: Float = sqrt(3.0) / 2.0 * 0.5

        let positions: [SIMD3<Float>] = [
            [0, height * 2.0 / 3.0, 0],      // 0: top vertex
            [-0.5, -height / 3.0, 0],        // 1: bottom-left
            [0.5, -height / 3.0, 0]         // 2: bottom-right
        ]

        let textureCoordinates: [SIMD2<Float>] = [
            [0.5, 1],   // top
            [0, 0],     // bottom-left
            [1, 0]     // bottom-right
        ]

        let normals: [SIMD3<Float>] = [
            [0, 0, 1],
            [0, 0, 1],
            [0, 0, 1]
        ]

        let indices: [Int] = [0, 1, 2]

        return TrivialMesh(
            label: "Triangle",
            indices: indices,
            positions: positions,
            textureCoordinates: textureCoordinates,
            normals: normals,
            tangents: nil,
            bitangents: nil,
            colors: nil
        )
    }
}
