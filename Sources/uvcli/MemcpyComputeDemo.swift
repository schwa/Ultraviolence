import Metal
import Ultraviolence

enum MemcpyComputeDemo {
    @MainActor
    static func main() throws {
        let source = """
        #import <metal_stdlib>
        #import <metal_logging>

        using namespace metal;

        uint gid [[thread_position_in_grid]];

        kernel void kernelMain(
            device char *src [[buffer(0)]],
            device char *dst [[buffer(1)]]
        ) {
            dst[gid] = src[gid];
        }
        """

        try MTLCaptureManager.shared().with(enabled: false) {
            let device = MTLCreateSystemDefaultDevice()!

            let inputBuffer = device.makeBuffer(length: 1_024, options: [])
            let outputBuffer = device.makeBuffer(length: 1_024, options: [])

            let kernel = try ComputeKernel(source: source, logging: true)
            let pipeline = ComputePipeline(computeKernel: kernel) {
                ComputeDispatch(threads: .init(width: 1, height: 1, depth: 1), threadsPerThreadgroup: .init(width: 1, height: 1, depth: 1))
            }
            .parameter("src", inputBuffer)
            .parameter("dst", outputBuffer)

            let compute = try Compute(logging: true)
            try compute.compute(pipeline)
        }
    }
}
