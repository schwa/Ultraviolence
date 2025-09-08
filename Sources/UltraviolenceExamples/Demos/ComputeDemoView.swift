import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import DemoKit

public struct ComputeDemoView: View {
    @State
    private var state: Result<Void, Error>?

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        Text("\(String(describing: state))")
            .task {
                do {
                    let source = """
                    #import <metal_stdlib>
                    #import <metal_logging>

                    using namespace metal;

                    uint gid [[thread_position_in_grid]];

                    kernel void kernelMain(
                        constant char *src [[buffer(0)]],
                        device char *dst [[buffer(1)]]
                    ) {
                        dst[gid] = src[gid];
                    }
                    """

                    try MTLCaptureManager.shared().with(enabled: false) {
                        let device = _MTLCreateSystemDefaultDevice()
                        let count = 1 * 1_024 * 1_024
                        let inputBuffer = try device.makeBuffer(collection: (0..<count).map { index in UInt8(index % 256) }, options: [.storageModeShared])
                        let outputBuffer = try device.makeBuffer(length: count, options: [.storageModeShared]).orThrow(.resourceCreationFailure("Failed to create output buffer."))
                        let kernel = try ComputeKernel(source: source)
                        let compute = try ComputePass {
                            try ComputePipeline(computeKernel: kernel) {
                                try ComputeDispatch(threadsPerGrid: .init(width: count, height: 1, depth: 1), threadsPerThreadgroup: .init(width: 1_024, height: 1, depth: 1))
                                    .parameter("src", buffer: inputBuffer)
                                    .parameter("dst", buffer: outputBuffer)
                            }
                        }
                        try compute.run()
                        guard [UInt8](inputBuffer.contents()) == [UInt8](outputBuffer.contents()) else {
                            throw UltraviolenceError.generic("Buffers do not match.")
                        }
                    }
                    state = .success(())
                }
                catch {
                    state = .failure(error)
                }
            }
    }
}

extension ComputeDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Compute",
            description: "Simple compute shader that copies data between GPU buffers",
            keywords: ["compute"]
        )
    }
}
