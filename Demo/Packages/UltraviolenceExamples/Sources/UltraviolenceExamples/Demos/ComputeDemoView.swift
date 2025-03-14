import SwiftUI
import Ultraviolence

public struct ComputeDemoView: View {
    @State
    private var state: Result<Void, Error>?

    public init() {
    }

    public var body: some View {
        Text("\(String(describing: state))")
            .task {
                let source = """
            #import <metal_stdlib>
            #import <metal_logging>

            using namespace metal;

            kernel void kernelMain(
            ) {
                os_log_default.log("Hello world from Metal.");
            }
            """

                do {
                    let kernel = try ComputeKernel(source: source, logging: true)
                    let compute = try ComputePass {
                        ComputePipeline(computeKernel: kernel) {
                            ComputeDispatch(threads: .init(width: 1, height: 1, depth: 1), threadsPerThreadgroup: .init(width: 1, height: 1, depth: 1))
                        }
                    }
                    try compute.run()
                    state = .success(())
                }
                catch {
                    state = .failure(error)
                }
            }
    }
}

extension ComputeDemoView: DemoView {
}
