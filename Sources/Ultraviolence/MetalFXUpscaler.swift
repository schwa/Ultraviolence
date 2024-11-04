import Metal
import MetalFX

// TODO: Placeholder.
public struct MetalFXUpscaler: RenderPass {
    public init(input: Texture) {
//        let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()
//        spatialScalerDescriptor.inputWidth = input.width
//        spatialScalerDescriptor.inputHeight = input.height
//        spatialScalerDescriptor.outputWidth = destination.width
//        spatialScalerDescriptor.outputHeight = destination.height
//        spatialScalerDescriptor.colorTextureFormat = source.pixelFormat
//        spatialScalerDescriptor.outputTextureFormat = destination.pixelFormat
//        spatialScalerDescriptor.colorProcessingMode = colorProcessingMode
//
//        let spatialScaler = try spatialScalerDescriptor.makeSpatialScaler(device: device)!
//        spatialScaler.colorTexture = source
//        spatialScaler.outputTexture = destination
//        self.spatialScaler = .init(spatialScaler)
    }

    public var body: some RenderPass {
        fatalError("Not implemented")
    }
}
