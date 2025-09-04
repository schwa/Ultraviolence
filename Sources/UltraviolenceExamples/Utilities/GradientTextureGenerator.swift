import Metal
import simd
import UltraviolenceSupport

public struct GradientTextureGenerator {
    
    public static func createThermalGradient(device: MTLDevice) throws -> MTLTexture {
        // Apple Event thermal palette colors
        let colors: [SIMD4<Float>] = [
            hexToRGBA("000000"), // Black
            hexToRGBA("073dff"), // Deep blue
            hexToRGBA("53d5fd"), // Cyan
            hexToRGBA("fefcdd"), // Light yellow
            hexToRGBA("ffec6a"), // Yellow
            hexToRGBA("f9d400"), // Orange
            hexToRGBA("a61904"), // Red
        ]
        
        return try createGradientTexture(device: device, colors: colors, size: 256)
    }
    
    public static func createGradientTexture(
        device: MTLDevice,
        colors: [SIMD4<Float>],
        size: Int = 256
    ) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type1D
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = size
        descriptor.height = 1
        descriptor.depth = 1
        descriptor.mipmapLevelCount = 1
        descriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw UltraviolenceError.resourceCreationFailure("Failed to create gradient texture")
        }
        texture.label = "Gradient Texture"
        
        // Generate gradient data
        var pixelData = [UInt8]()
        pixelData.reserveCapacity(size * 4)
        
        for i in 0..<size {
            let t = Float(i) / Float(size - 1)
            let color = interpolateGradient(colors: colors, t: t)
            
            // Convert to 0-255 range
            pixelData.append(UInt8(color.x * 255))
            pixelData.append(UInt8(color.y * 255))
            pixelData.append(UInt8(color.z * 255))
            pixelData.append(UInt8(color.w * 255))
        }
        
        texture.replace(
            region: MTLRegionMake1D(0, size),
            mipmapLevel: 0,
            withBytes: pixelData,
            bytesPerRow: size * 4
        )
        
        return texture
    }
    
    private static func interpolateGradient(colors: [SIMD4<Float>], t: Float) -> SIMD4<Float> {
        guard colors.count >= 2 else {
            return colors.first ?? SIMD4<Float>(0, 0, 0, 1)
        }
        
        let scaledT = t * Float(colors.count - 1)
        let index = Int(scaledT)
        let fraction = scaledT - Float(index)
        
        if index >= colors.count - 1 {
            return colors.last!
        }
        
        let color1 = colors[index]
        let color2 = colors[index + 1]
        
        // Linear interpolation
        return mix(color1, color2, t: SIMD4<Float>(repeating: fraction))
    }
    
    private static func hexToRGBA(_ hex: String) -> SIMD4<Float> {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        guard hexString.count == 6 else {
            return SIMD4<Float>(0, 0, 0, 1)
        }
        
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)
        
        let r = Float((hexNumber & 0xff0000) >> 16) / 255.0
        let g = Float((hexNumber & 0x00ff00) >> 8) / 255.0
        let b = Float((hexNumber & 0x0000ff)) / 255.0
        
        return SIMD4<Float>(r, g, b, 1.0)
    }
}