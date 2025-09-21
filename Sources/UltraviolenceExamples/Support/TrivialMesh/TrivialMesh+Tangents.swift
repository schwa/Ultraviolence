import Foundation
import MikkTSpace

extension SMikkTSpaceContext {
    var mesh: TrivialMesh {
        get {
            m_pUserData!.assumingMemoryBound(to: TrivialMesh.self).pointee
        }
    }
}

extension TrivialMesh {

    func generateTextureCoordinates() -> Self {
        var copy = self



//        Compute uv from vertex position in spherical coordinates:
//        u = atan2(z, x) / (2π) + 0.5,
//        v = y_normalized or v = acos(y / |pos|) / π.
//            •    Works okay for roughly spherical meshes.
        // Spherical map
        copy.textureCoordinates = copy.positions.map { p in
            // If your mesh isn't centered, consider subtracting its centroid first.
            let x = Double(p.x), y = Double(p.y), z = Double(p.z)

            // u: [-π, π] → [0,1]
            var u = atan2(z, x) / (2.0 * .pi) + 0.5

            // v: [0, π] → [0,1]
            let r = sqrt(x*x + y*y + z*z)
            // Avoid NaNs from slight FP drift: clamp y/r into [-1, 1]
            let cosTheta = r > 0 ? max(-1.0, min(1.0, y / r)) : 0.0
            let v = acos(cosTheta) / .pi

            // Wrap u cleanly into [0,1] in case atan2 gives -ε or 1+ε
            u = u - floor(u)

            return SIMD2<Float>(Float(u), Float(v))
        }

        return copy
    }







    func generateTangents() -> Self {
        var copy = self


        copy.tangents = Array(repeating: SIMD3<Float>.zero, count: copy.positions.count)
        copy.bitangents = Array(repeating: SIMD3<Float>.zero, count: copy.positions.count)

        let result = withUnsafeMutablePointer(to: &copy) { mesh in
            var interface = SMikkTSpaceInterface()
            interface.m_getNumFaces = { context in
                let mesh = context!.pointee.mesh
                return Int32(mesh.indices.count / 3)
            }
            interface.m_getNumVerticesOfFace = { context, face in
                return 3
            }
            interface.m_getPosition = { context, positionOut, face, vert in
                let mesh = context!.pointee.mesh
                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
                let position = mesh.positions[index]
                positionOut![0] = position.x
                positionOut![1] = position.y
                positionOut![2] = position.z
            }
            interface.m_getNormal = { context, positionOut, face, vert in
                let mesh = context!.pointee.mesh
                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
                let normal = mesh.normals![index]
                positionOut![0] = normal.x
                positionOut![1] = normal.y
                positionOut![2] = normal.z
            }
            interface.m_getTexCoord = { context, positionOut, face, vert in
                let mesh = context!.pointee.mesh
                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
                let textureCoordinates = mesh.textureCoordinates![index]
                positionOut![0] = textureCoordinates.x
                positionOut![1] = textureCoordinates.y
            }
//            interface.m_setTSpaceBasic = { context, fvTangent, fSign, face, vert in
//                let meshPointer = context!.pointee.m_pUserData!.assumingMemoryBound(to: TrivialMesh.self)
//                let mesh = meshPointer.pointee
//                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
//                let tangent = SIMD3<Float>(fvTangent![0], fvTangent![1], fvTangent![2])
//                meshPointer.pointee.tangents![index] = tangent
//            }

            interface.m_setTSpace = { context, fvTangent, fvBiTangent, fMagS, fMagT, bIsOrientationPreserving, face, vert in
                let meshPointer = context!.pointee.m_pUserData!.assumingMemoryBound(to: TrivialMesh.self)
                let mesh = meshPointer.pointee
                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
                let tangent = SIMD3<Float>(fvTangent![0], fvTangent![1], fvTangent![2])
                meshPointer.pointee.tangents![index] = tangent
                let bitangents = SIMD3<Float>(fvBiTangent![0], fvBiTangent![1], fvBiTangent![2])
                meshPointer.pointee.bitangents![index] = bitangents
            }

            var context = SMikkTSpaceContext()
            context.m_pUserData = UnsafeMutableRawPointer(mesh)
            return withUnsafeMutablePointer(to: &interface) { interface in
                context.m_pInterface = interface
                return genTangSpaceDefault(&context)
            }
        }
        assert(result != 0, "Failed to generate tangents")
        return copy
    }
}

//        // The call-back m_setTSpaceBasic() is sufficient for basic normal mapping.
//
//        // This function is used to return the tangent and fSign to the application.
//        // fvTangent is a unit length vector.
//        // For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
//        // bitangent = fSign * cross(vN, tangent);
//        // Note that the results are returned unindexed. It is possible to generate a new index list
//        // But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
//        // DO NOT! use an already existing index list.
//        void (*m_setTSpaceBasic)(const SMikkTSpaceContext * pContext, const float fvTangent[], const float fSign, const int iFace, const int iVert);
//
//        // This function is used to return tangent space results to the application.
//        // fvTangent and fvBiTangent are unit length vectors and fMagS and fMagT are their
//        // true magnitudes which can be used for relief mapping effects.
//        // fvBiTangent is the "real" bitangent and thus may not be perpendicular to fvTangent.
//        // However, both are perpendicular to the vertex normal.
//        // For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
//        // fSign = bIsOrientationPreserving ? 1.0f : (-1.0f);
//        // bitangent = fSign * cross(vN, tangent);
//        // Note that the results are returned unindexed. It is possible to generate a new index list
//        // But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
//        // DO NOT! use an already existing index list.
//        void (*m_setTSpace)(const SMikkTSpaceContext * pContext, const float fvTangent[], const float fvBiTangent[], const float fMagS, const float fMagT,
//                            const tbool bIsOrientationPreserving, const int iFace, const int iVert);
//    } SM





