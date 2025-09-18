import Metal
import simd

struct HeatParameters {
    var mousePosition: SIMD2<Float>      // 8 bytes (offset: 0)
    var mouseDirection: SIMD2<Float>     // 8 bytes (offset: 8)
    var heatIntensity: Float             // 4 bytes (offset: 16)
    var radius: Float                    // 4 bytes (offset: 20)
    var fadeDamping: Float               // 4 bytes (offset: 24)
    var sizeDamping: Float               // 4 bytes (offset: 28)
    var textureSize: SIMD2<UInt32>       // 8 bytes (offset: 32)
    var isInteracting: Float             // 4 bytes (offset: 40)
    var _padding_final: UInt32 = 0       // 4 bytes (offset: 44) - total: 48 bytes

    init(
        mousePosition: SIMD2<Float> = SIMD2<Float>(0.5, 0.5),
        mouseDirection: SIMD2<Float> = SIMD2<Float>(0, 0),
        heatIntensity: Float = 0,
        radius: Float = 50,
        fadeDamping: Float = 0.98,
        sizeDamping: Float = 0.8,
        textureSize: SIMD2<UInt32> = SIMD2<UInt32>(256, 256),
        isInteracting: Bool = false
    ) {
        self.mousePosition = mousePosition
        self.mouseDirection = mouseDirection
        self.heatIntensity = heatIntensity
        self.radius = radius
        self.fadeDamping = fadeDamping
        self.sizeDamping = sizeDamping
        self.textureSize = textureSize
        self.isInteracting = isInteracting ? 1.0 : 0.0
        self._padding_final = 0
    }
}
