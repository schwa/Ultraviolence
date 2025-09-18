import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport

public extension Draw {
    init(mtkMesh: MTKMesh) {
        self.init { encoder in
            encoder.setVertexBuffers(of: mtkMesh)
            encoder.draw(mtkMesh)
        }
    }
}

