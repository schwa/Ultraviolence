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

extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self.init([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [translation.x, translation.y, translation.z, 1]
        ])
    }

    init(yRotation: Angle) {
        let radians = Float(yRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, 0, s, 0],
            [0, 1, 0, 0],
            [-s, 0, c, 0],
            [0, 0, 0, 1]
        ])
    }

    init(zRotation: Angle) {
        let radians = Float(zRotation.radians)
        let c = cos(radians)
        let s = sin(radians)
        self.init([
            [c, -s, 0, 0],
            [s, c, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ])
    }
}

struct SliderField: View {

    let label: String

    @Binding
    var value: Float

    var `in`: ClosedRange<Float>

    @SwiftUI.State
    var popupShown = false

    var body: some View {
        HStack {
            Text("\(label)")
            Text("\(value)")
            Button("-") {
                popupShown = true
            }
        }
        .popover(isPresented: $popupShown) {
            Slider(value: $value, in: `in`)
            .controlSize(.mini)
            .frame(width: 200)
            .padding()
        }
    }
}
