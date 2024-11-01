import CoreGraphics
import SwiftUI

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
