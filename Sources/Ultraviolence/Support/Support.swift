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
            let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError("Missing render command encoder")
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
            let renderCommandEncoder = environmentValues.computeCommandEncoder.orFatalError("Missing compute command encoder")
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

internal extension ObjectIdentifier {
    var shortId: String {
        let description = String(describing: self)
        let pattern = #/^ObjectIdentifier\(0x(?'hex'[0-9a-f]+)\)$/#
        guard let match = description.firstMatch(of: pattern) else {
            fatalError("Cannot get shortID for \(self)")
        }
        guard let int = UInt64(match.output.hex, radix: 16) else {
            fatalError("Cannot get shortID for \(self)")
        }

        let alphabet: [Character] = Array("klmnopqrstuvwxyz")
        func encode(_ value: UInt64, minLength: Int = 1) -> String {
            precondition(minLength >= 1, "minLength must be ≥ 1")

            var v = value
            var out: [Character] = []

            if v == 0 {
                // Zero is just 'k' repeated to the requested minimum length.
                return String(repeating: "k", count: minLength)
            }

            while v > 0 {
                let nibble = Int(v & 0xF)
                out.append(alphabet[nibble])  // least-significant nibble first
                v >>= 4
            }

            // Pad to minimum length with 'k' (the zero digit), then reverse to big-endian.
            while out.count < minLength { out.append("k") }
            return String(out.reversed())
        }
        return encode(int)
    }
}
