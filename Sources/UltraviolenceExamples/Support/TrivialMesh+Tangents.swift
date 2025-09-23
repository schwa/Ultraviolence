import MikkTSpace

extension SMikkTSpaceContext {
    var mesh: TrivialMesh {
        get {
            m_pUserData!.assumingMemoryBound(to: TrivialMesh.self).pointee
        }
    }
}


extension TrivialMesh {
    func generateTangents() -> Self {
        var copy = self

        copy.tangents = Array(repeating: SIMD3<Float>.zero, count: copy.positions.count)
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
            interface.m_setTSpaceBasic = { context, fvTangent, fSign, face, vert in
                let meshPointer = context!.pointee.m_pUserData!.assumingMemoryBound(to: TrivialMesh.self)
                let mesh = meshPointer.pointee
                let index = Int(mesh.indices[Int(face) * 3 + Int(vert)])
                let tangent = SIMD3<Float>(fvTangent![0], fvTangent![1], fvTangent![2])
                meshPointer.pointee.tangents![index] = tangent
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




