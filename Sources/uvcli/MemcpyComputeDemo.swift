import Metal
import Ultraviolence
internal import UltraviolenceSupport

enum MemcpyComputeDemo {
    @MainActor
    static func main() throws {
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
            let device = MTLCreateSystemDefaultDevice()!

            // TODO: we're taking it on faith that the memcpy is happening. Add some data to input and check output at end.

            let count = 16 * 1_024 * 1_024
            let inputBuffer = try device.makeBuffer(collection: (0..<count).map { index in UInt8(index % 256) }, options: [.storageModeShared])
            let outputBuffer = device.makeBuffer(length: count, options: [.storageModeShared])!

            let kernel = try ComputeKernel(source: source, logging: true)
            let pipeline = ComputePipeline(computeKernel: kernel) {
                ComputeDispatch(threads: .init(width: count, height: 1, depth: 1), threadsPerThreadgroup: .init(width: 1_024, height: 1, depth: 1))
                .parameter("src", buffer: inputBuffer)
                .parameter("dst", buffer: outputBuffer)
            }
            let compute = try Compute(logging: true)
            try compute.compute(pipeline)
            print([UInt8](inputBuffer.contents()) == [UInt8](outputBuffer.contents()))
        }
    }
}