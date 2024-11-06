import CoreGraphics
import Foundation
import Metal
import MetalKit
internal import ModelIO
import simd
import SwiftUI
import Ultraviolence
internal import UltraviolenceSupport

public struct Teapot: Geometry {
    public init() {
        // This line intentionally left blank.
    }

    public func mesh() throws -> Mesh {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let url = try Bundle.module.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        // swiftlint:disable:next force_cast
        let mdlMesh = mdlAsset.object(at: 0) as! MDLMesh
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
        return .mtkMesh(mtkMesh)
    }
}

public extension SIMD4 where Scalar == Float {
    static let red = SIMD4<Float>([1, 0, 0, 1])
}
