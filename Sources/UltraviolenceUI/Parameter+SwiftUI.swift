import SwiftUI
import Ultraviolence

// TODO: #110 Also it could take a SwiftUI environment(). Also SRGB?
public extension Element {
    func parameter(_ name: String, color: Color, functionType: MTLFunctionType? = nil) -> some Element {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let color = color.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil) else {
            preconditionFailure("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            preconditionFailure("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return parameter(name, value, functionType: functionType)
    }
}
