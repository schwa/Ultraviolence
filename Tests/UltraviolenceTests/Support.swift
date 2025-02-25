import Accelerate
import CoreGraphics
import CoreImage
// swiftlint:disable:next duplicate_imports
import CoreImage.CIFilterBuiltins
import Testing
@testable import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

extension Graph {
    func element<V>(at path: [Int], type: V.Type) -> V {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.element as! V
    }
}

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
        // TODO: These parameters may not be compatible with the passed in color space.
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
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

@Test
func testHistogram() throws {
    let red = try Histogram(image: CGImage.withColor(red: 1, green: 0, blue: 0)).peaks
    #expect(red.alpha == 1)
    #expect(red.red > red.green && red.red > red.blue)
    print(red)
    let green = try Histogram(image: CGImage.withColor(red: 0, green: 1, blue: 0)).peaks
    #expect(green.alpha == 1)
    #expect(green.green > red.red && green.green > red.blue)
    print(green)
    let blue = try Histogram(image: CGImage.withColor(red: 0, green: 0, blue: 1)).peaks
    #expect(blue.alpha == 1)
    #expect(blue.blue > red.red && blue.blue > red.green)
    print(blue)
}

func goldenImage(named name: String) -> CGImage {
    let url = Bundle.module.url(forResource: name, withExtension: "png")!
    let data = try! Data(contentsOf: url)
    let imageSource = CGImageSourceCreateWithData(data as CFData, nil)!
    return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!
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
