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
        SetupModifier()
            .onSetupEnter {
                scaler = try makeScaler()
            }
            .onWorkloadEnter {
                var scaler = try scaler.orThrow(.undefined)
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
        let device = try _MTLCreateSystemDefaultDevice()
        return try descriptor.makeSpatialScaler(device: device).orThrow(.undefined)
    }
}

// TODO: #64 Experimental solution. Ergonmonics are bad however.
internal struct SetupModifier: Element, BodylessElement {
    fileprivate var _setupEnter: (() throws -> Void)?
    fileprivate var _setupExit: (() throws -> Void)?
    fileprivate var _workloadEnter: (() throws -> Void)?
    fileprivate var _workloadExit: (() throws -> Void)?

    init() {
        // This line intentionally left blank
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func setupEnter(_ node: Node) throws {
        try _setupEnter?()
    }

    func setupExit(_ node: Node) throws {
        try _setupExit?()
    }

    func workloadEnter(_ node: Node) throws {
        try _workloadEnter?()
    }

    func workloadExit(_ node: Node) throws {
        try _workloadExit?()
    }
}

internal extension SetupModifier {
    func onSetupEnter(_ action: @escaping () throws -> Void) -> SetupModifier {
        var modifier = self
        modifier._setupEnter = action
        return modifier
    }
    func onSetupExit(_ action: @escaping () throws -> Void) -> SetupModifier {
        var modifier = self
        modifier._setupExit = action
        return modifier
    }
    func onWorkloadEnter(_ action: @escaping () throws -> Void) -> SetupModifier {
        var modifier = self
        modifier._workloadEnter = action
        return modifier
    }
    func onWorkloadExit(_ action: @escaping () throws -> Void) -> SetupModifier {
        var modifier = self
        modifier._workloadExit = action
        return modifier
    }
}
#endif
