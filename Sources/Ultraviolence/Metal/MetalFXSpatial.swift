#if canImport(MetalFX)
import Metal
import MetalFX
import UltraviolenceSupport

public struct MetalFXSpatial: Element {
    @UVState
    var scaler: MTLFXSpatialScaler?

    var inputTexture: MTLTexture
    var outputTexture: MTLTexture

    @UVEnvironment(\.commandBuffer)
    var commandBuffer

    public init(inputTexture: MTLTexture, outputTexture: MTLTexture) {
        self.inputTexture = inputTexture
        self.outputTexture = outputTexture
    }

    public var body: some Element {
        AnyBodylessElement()
            .onSetupEnter {
                scaler = try makeScaler()
            }
            .onWorkloadEnter {
                var scaler = try scaler.orThrow(.resourceCreationFailure("MetalFX spatial scaler not initialized"))
                // TODO: #55, #70 Instead of doing this we need to have some kind of "onChange" and merely mark "setupNeeded"
                if scaler.outputWidth != outputTexture.width || scaler.outputHeight != outputTexture.height {
                    scaler = try makeScaler()
                    self.scaler = scaler
                }
                let commandBuffer = try commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
                scaler.colorTexture = inputTexture
                scaler.inputContentWidth = inputTexture.width
                scaler.inputContentHeight = inputTexture.height
                scaler.outputTexture = outputTexture
                scaler.encode(commandBuffer: commandBuffer)
            }
    }

    func makeScaler() throws -> MTLFXSpatialScaler {
        let descriptor = MTLFXSpatialScalerDescriptor()
        descriptor.colorTextureFormat = inputTexture.pixelFormat
        descriptor.outputTextureFormat = outputTexture.pixelFormat
        descriptor.inputWidth = inputTexture.width
        descriptor.inputHeight = inputTexture.height
        descriptor.outputWidth = outputTexture.width
        descriptor.outputHeight = outputTexture.height
        let device = _MTLCreateSystemDefaultDevice()
        return try descriptor.makeSpatialScaler(device: device).orThrow(.resourceCreationFailure("Failed to create MetalFX spatial scaler"))
    }
}
#endif
