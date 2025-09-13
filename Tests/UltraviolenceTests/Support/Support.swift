import Accelerate
import CoreGraphics
import CoreImage
// swiftlint:disable:next duplicate_imports
import CoreImage.CIFilterBuiltins
import Testing
@testable import Ultraviolence
import UltraviolenceSupport
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

// swiftlint:disable force_unwrapping

extension CGImage {
    func isEqualToGoldenImage(named name: String) throws -> Bool {
        do {
            let goldenImage = try goldenImage(named: name)
            guard try imageCompare(self, goldenImage) else {
                let url = URL(fileURLWithPath: "/tmp/\(name).png")
                try self.write(to: url)
                url.revealInFinder()

                throw UltraviolenceError.validationError("Images are not equal")
            }
            return true
        }
        catch {
            let url = URL(fileURLWithPath: "/tmp/\(name).png")
            try self.write(to: url)
            // Image written to /tmp for debugging
            return false
        }
    }
}

func goldenImage(named name: String) throws -> CGImage {
    let url = Bundle.module.resourceURL!.appendingPathComponent("Golden Images").appendingPathComponent(name).appendingPathExtension("png")
    let data = try Data(contentsOf: url)
    let imageSource = try CGImageSourceCreateWithData(data as CFData, nil).orThrow(.resourceCreationFailure("Failed to create image source from data"))
    return try CGImageSourceCreateImageAtIndex(imageSource, 0, nil).orThrow(.resourceCreationFailure("Failed to create image from source"))
}

func imageCompare(_ image1: CGImage, _ image2: CGImage) throws -> Bool {
    let ciContext = CIContext()

    let ciImage1 = CIImage(cgImage: image1)
    let ciImage2 = CIImage(cgImage: image2)

    let difference = CIFilter.differenceBlendMode()
    difference.setValue(ciImage1, forKey: kCIInputImageKey)
    difference.setValue(ciImage2, forKey: kCIInputBackgroundImageKey)

    let differenceImage = difference.outputImage!
    let differenceCGImage = ciContext.createCGImage(differenceImage, from: differenceImage.extent)!

    let histogram = try Histogram(image: differenceCGImage)
    assert(histogram.relativeAlpha[255] == 1.0)
    return histogram.relativeRed[0] == 1.0 && histogram.relativeGreen[0] == 1.0 && histogram.relativeBlue[0] == 1.0
}

// TODO: System
// extension NodeGraph {
//    func element<V>(at path: [Int], type: V.Type) -> V {
//        var node: Node = root
//        for index in path {
//            node = node.children[index]
//        }
//        return node.element as! V
//    }
// }

extension CGImage {
    func write(to url: URL) throws {
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, self, nil)
        CGImageDestinationFinalize(destination)
    }

    func toVimage() throws -> vImage.PixelBuffer<vImage.Interleaved8x4> {
        let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8 * 4, colorSpace: colorSpace, bitmapInfo: .init(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue))!
        return try vImage.PixelBuffer(cgImage: self, cgImageFormat: &format, pixelFormat: vImage.Interleaved8x4.self)
    }

    static func withColor(colorSpace: CGColorSpace? = nil, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> CGImage {
        let colorSpace = colorSpace ?? CGColorSpaceCreateDeviceRGB()
        // Assert that the color space is RGB-based to ensure compatibility with our bitmap parameters
        assert(colorSpace.model == .rgb, "Color space must be RGB-based for compatibility with CGImageAlphaInfo.noneSkipFirst")
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        guard let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            fatalError("Failed to create CGContext - likely due to incompatible color space and bitmap info combination")
        }
        context.setFillColor(red: red, green: green, blue: blue, alpha: alpha)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return context.makeImage()!
    }
}

struct Histogram {
    var pixelCount: Int
    var red: [Int]
    var green: [Int]
    var blue: [Int]
    var alpha: [Int]

    init(image: CGImage) throws {
        let pixelBuffer = try image.toVimage()
        pixelCount = image.width * image.height
        let histogram = pixelBuffer.histogram()
        alpha = histogram.0.map { Int($0) }
        red = histogram.1.map { Int($0) }
        green = histogram.2.map { Int($0) }
        blue = histogram.3.map { Int($0) }
    }

    var peaks: (red: Double, green: Double, blue: Double, alpha: Double) {
        func peak(_ channel: [Int]) -> Double {
            let max = channel.max()!
            let index = channel.firstIndex(of: max)!
            return Double(index) / Double(channel.count - 1)
        }
        return (peak(red), peak(green), peak(blue), peak(alpha))
    }

    var relativeRed: [Double] {
        red.map { Double($0) / Double(pixelCount) }
    }

    var relativeGreen: [Double] {
        green.map { Double($0) / Double(pixelCount) }
    }

    var relativeBlue: [Double] {
        blue.map { Double($0) / Double(pixelCount) }
    }

    var relativeAlpha: [Double] {
        alpha.map { Double($0) / Double(pixelCount) }
    }
}

// MARK: -

@Test
func testHistogram() throws {
    let red = try Histogram(image: CGImage.withColor(red: 1, green: 0, blue: 0)).peaks
    #expect(red.alpha == 1)
    #expect(red.red > red.green && red.red > red.blue)
    let green = try Histogram(image: CGImage.withColor(red: 0, green: 1, blue: 0)).peaks
    #expect(green.alpha == 1)
    #expect(green.green > red.red && green.green > red.blue)
    let blue = try Histogram(image: CGImage.withColor(red: 0, green: 0, blue: 1)).peaks
    #expect(blue.alpha == 1)
    #expect(blue.blue > red.red && blue.blue > red.green)
}

#if canImport(AppKit)
public extension URL {
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
}
#endif

@MainActor
class TestMonitor {
    static let shared = TestMonitor()

    var updates: [String] = []
    var values: [String: Any] = [:]
    var observations: [(phase: String, element: String, counter: Int, env: String)] = []

    func reset() {
        updates.removeAll()
        values.removeAll()
        observations.removeAll()
    }

    func logUpdate(_ message: String) {
        updates.append(message)
    }

    func record(phase: String, element: String, counter: Int = -1, env: String = "") {
        observations.append((phase: phase, element: element, counter: counter, env: env))
    }
}

// Test helper extension
extension StructuralIdentifier.Atom {
    var index: Int? {
        if case .index(let value) = component {
            return value
        }
        return nil
    }

    var explicit: AnyHashable? {
        if case .explicit(let value) = component {
            return value
        }
        return nil
    }
}
