import Foundation
import CoreGraphics
import SwiftUI
import Metal
internal import ModelIO
import MetalKit
import Ultraviolence

public struct Teapot: Geometry {
    public init() {
    }

    public func mesh() throws -> Mesh {

        let device = MTLCreateSystemDefaultDevice()!



        let url = Bundle.module.url(forResource: "teapot", withExtension: "obj")!
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = mdlAsset.object(at: 0) as! MDLMesh
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        return .mtkMesh(mtkMesh)
    }
}

 
