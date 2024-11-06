import Metal
import simd
internal import UltraviolenceSupport

public struct Visitor {
    public var device: MTLDevice
    public var environment: [[VisitorState]]

    public enum Phase {
        case setup
        case workload
    }

    public init(device: MTLDevice) {
        self.device = device
        self.environment = [[]]
    }

    private mutating func push(_ state: [VisitorState]) {
        environment.append(state)
    }

    private mutating func pop() {
        environment.removeLast()
    }

    public mutating func with<R>(_ state: [VisitorState], _ body: (inout Self) throws -> R) rethrows -> R {
        push(state)
        defer {
            pop()
        }
        return try body(&self)
    }

    // TODO: Make sure all `insert()` usages would not be better replaced with `with()`.
    public mutating func insert(_ state: VisitorState) {
        environment[environment.count - 1].append(state)
    }

    private var logDepth: Int = 0
    static let logVisitor = ProcessInfo.processInfo.environment["LOG_VISITOR"].isTrue

    mutating func log<T, R>(node: T, body: (inout Self) throws -> R) rethrows -> R where T: RenderPass {
        if !Self.logVisitor {
            return try body(&self)
        }

        let prefix = String(repeating: "  ", count: logDepth)
        let name = "\(type(of: node))"
        let shortName = name.prefixMatch(of: #/[^<]*/#)!.output

        logger?.log("\(prefix)ENTER \(shortName)")
        defer {
            logger?.log("\(prefix)EXIT \(shortName)")
            logDepth -= 1
        }
        logDepth += 1
        return try body(&self)
    }
}

// MARK: -

public extension Visitor {
    func dump() {
        for environment in self.environment {
            for state in environment {
                let meta = VisitorState.Meta(state)
                print(meta)
            }
        }
    }
}
