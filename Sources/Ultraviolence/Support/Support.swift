import Metal
internal import os
import UltraviolenceSupport

public extension UltraviolenceError {
    static func missingEnvironment(_ key: PartialKeyPath<UVEnvironmentValues>) -> Self {
        missingEnvironment("\(key)")
    }
}

public extension Element {
    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage, stages: MTLRenderStages) -> some Element {
        onWorkloadEnter { environmentValues in
            let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError()
            renderCommandEncoder.useResource(resource, usage: usage, stages: stages)
        }
    }

    @ElementBuilder
    func useResource(_ resource: (any MTLResource)?, usage: MTLResourceUsage, stages: MTLRenderStages) -> some Element {
        if let resource {
            self.useResource(resource, usage: usage, stages: stages)
        }
        else {
            self
        }
    }
}

public extension Element {
    func useComputeResource(_ resource: any MTLResource, usage: MTLResourceUsage) -> some Element {
        onWorkloadEnter { environmentValues in
            let renderCommandEncoder = environmentValues.computeCommandEncoder.orFatalError()
            renderCommandEncoder.useResource(resource, usage: usage)
        }
    }

    @ElementBuilder
    func useComputeResource(_ resource: (any MTLResource)?, usage: MTLResourceUsage) -> some Element {
        if let resource {
            self.useComputeResource(resource, usage: usage)
        }
        else {
            self
        }
    }
}

internal func abbreviatedTypeName<T>(of t: T) -> String {
    let name = "\(type(of: t))"
    return String(name[..<(name.firstIndex(of: "<") ?? name.endIndex)])
}
