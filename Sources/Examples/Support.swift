import CoreGraphics
import Foundation
import Metal
import MetalKit
internal import ModelIO
import SwiftUI
import Ultraviolence

public struct Teapot: Geometry {
    public init() {
        // This line intentionally left blank.
    }

    public func mesh() throws -> Mesh {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "teapot", withExtension: "obj")!
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        // swiftlint:disable:next force_cast
        let mdlMesh = mdlAsset.object(at: 0) as! MDLMesh
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        return .mtkMesh(mtkMesh)
    }
}
