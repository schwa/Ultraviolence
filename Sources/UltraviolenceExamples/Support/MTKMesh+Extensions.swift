import MetalKit
import UltraviolenceSupport

public extension MTKMesh {
    static func teapot(options: MTKMesh.Options = []) -> MTKMesh {
        do {
            return try MTKMesh(name: "teapot", bundle: .module, options: options)
        }
        catch {
            fatalError("\(error)")
        }
    }
}
