import CoreGraphics
import SwiftUI
import Metal
import ModelIO
import MetalKit
import Ultraviolence

extension Color {
    func float4() -> SIMD4<Float> {
        let cgColor = resolve(in: .init()).cgColor
        let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
        guard let convertedColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
            fatalError()
        }
        guard let components = convertedColor.components?.map(Float.init) else {
            fatalError()
        }
        return SIMD4<Float>(components[0], components[1], components[2], components[3])
    }
}

struct SIMDColorPicker: View {
    @Binding
    var value: SIMD4<Float>

    var body: some View {
        Grid(alignment: .trailing) {
            GridRow {
                Text("Red")
                Slider(value: $value.x)
            }
            GridRow {
                Text("Green")
                Slider(value: $value.y)
            }
            GridRow {
                Text("Blue")
                Slider(value: $value.z)
            }
            GridRow {
                Text("Alpha")
                Slider(value: $value.w)
            }
        }
        .frame(maxWidth: 80)
        .controlSize(.mini)
    }

}

struct Teapot: Geometry {
    func mesh() throws -> Mesh {
        let url = Bundle.main.url(forResource: "teapot", withExtension: "obj")!
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: MTLCreateSystemDefaultDevice()!))
        let mdlMesh = mdlAsset.object(at: 0) as! MDLMesh
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: MTLCreateSystemDefaultDevice()!)
        return .mtkMesh(mtkMesh)
    }
}
