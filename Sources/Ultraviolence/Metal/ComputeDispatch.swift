import Metal
import UltraviolenceSupport

public struct ComputeDispatch: Element, BodylessElement {
    private enum Dimensions {
        case threadgroupsPerGrid(MTLSize)
        case threadsPerGrid(MTLSize)
    }

    private var dimensions: Dimensions
    private var threadsPerThreadgroup: MTLSize

    public init(threadgroups: MTLSize, threadsPerThreadgroup: MTLSize) throws {
        self.dimensions = .threadgroupsPerGrid(threadgroups)
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    public init(threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) throws {
        let device = _MTLCreateSystemDefaultDevice()
        guard device.supportsFamily(.apple4) else {
            try _throw(UltraviolenceError.deviceCababilityFailure("Non-uniform threadgroup sizes require Apple GPU Family 4+ (A11 or later)"))
        }
        self.dimensions = .threadsPerGrid(threadsPerGrid)
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    func workloadEnter(_ node: Node) throws {
        guard let computeCommandEncoder = node.environmentValues.computeCommandEncoder, let computePipelineState = node.environmentValues.computePipelineState else {
            preconditionFailure("No compute command encoder/compute pipeline state found.")
        }
        computeCommandEncoder.setComputePipelineState(computePipelineState)

        switch dimensions {
        case .threadgroupsPerGrid(let threadgroupCount):
            computeCommandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)
        case .threadsPerGrid(let threads):
            computeCommandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }

    nonisolated func requiresSetup(comparedTo old: Self) -> Bool {
        // ComputeDispatch only dispatches during workload, never needs setup
        false
    }
}
