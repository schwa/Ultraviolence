import Metal
import Ultraviolence

enum HelloWorldComputeDemo {
    @MainActor
    static func main() throws {
        let source = """
        #import <metal_stdlib>
        #import <metal_logging>

        using namespace metal;

        kernel void kernelMain(
        ) {
            os_log_default.log("Hello world from Metal.");
        }
        """

        try MTLCaptureManager.shared().with(enabled: false) {
            let kernel = try ComputeKernel(source: source, logging: true)
            let pipeline = ComputePipeline(computeKernel: kernel) {
                ComputeDispatch(threads: .init(width: 1, height: 1, depth: 1), threadsPerThreadgroup: .init(width: 1, height: 1, depth: 1))
            }
            let compute = try Compute(logging: true)
            try compute.compute(pipeline)
        }
    }
}
