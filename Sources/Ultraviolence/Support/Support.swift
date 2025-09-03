import Metal
internal import os
import UltraviolenceSupport

internal extension Element {
    var shortDescription: String {
        "\(type(of: self))"
    }
}

public extension UltraviolenceError {
    static func missingEnvironment(_ key: PartialKeyPath<UVEnvironmentValues>) -> Self {
        missingEnvironment("\(key)")
    }
}

@MainActor
internal extension Node {
    var shortDescription: String {
        self.element?.shortDescription ?? "<empty>"
    }
}

public extension Element {
    // TODO: #105 Need a compute variant of this.
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
