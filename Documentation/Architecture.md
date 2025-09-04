# Ultraviolence Architecture

## Overview

Ultraviolence is a declarative Metal rendering framework for Swift, inspired by SwiftUI's architecture. It provides a high-level, composable API for building Metal rendering pipelines while maintaining the performance and flexibility of Metal.

## Core Concepts

### 1. Element Protocol

The `Element` protocol is the fundamental building block of Ultraviolence, analogous to SwiftUI's `View` protocol.

```swift
public protocol Element {
    associatedtype Body: Element
    var body: Body { get throws }
}
```

Elements compose hierarchically to form a rendering tree. Each element can either:

- Return other elements via its `body` property (compositional elements)
- Perform actual Metal operations (bodyless elements)

### 2. BodylessElement

`BodylessElement` represents elements that perform actual Metal operations rather than composition:

```swift
public protocol BodylessElement: Element {
    func setupEnter(_ node: Node) throws
    func setupExit(_ node: Node) throws
    func workloadEnter(_ node: Node) throws
    func workloadExit(_ node: Node) throws
}
```

These elements interact directly with Metal command encoders and perform rendering operations.

### 3. Rendering Graph

The framework manages a graph that transforms your declarative element tree into Metal commands:

- Elements are expanded into an internal graph structure
- The graph handles state changes and selective rebuilding
- Two-phase processing: setup (one-time) and workload (per-frame)

### 4. State Management

Ultraviolence provides SwiftUI-like property wrappers for state management:

#### @UVState

Local state within an element:

```swift
@UVState private var rotation: Float = 0
```

#### @UVBinding

Two-way binding to external state:

```swift
@UVBinding var isEnabled: Bool
```

#### @UVObservedObject

Observe changes in external objects:

```swift
@UVObservedObject var viewModel: MyViewModel
```

#### @UVEnvironment

Access values from the environment:

```swift
@UVEnvironment(\.device) var device
```

### 5. Environment System

The environment propagates values down the element tree:

```swift
public struct UVEnvironmentValues {
    // Predefined environment keys
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var commandBuffer: MTLCommandBuffer?
    var renderPassDescriptor: MTLRenderPassDescriptor?
    // ... and more
}
```

Elements can read from and modify the environment for their children.

## Module Structure

### Core Framework (Ultraviolence)

The main framework containing:

- Element protocol and core types
- State management system
- Environment system
- Built-in rendering elements
- Metal integration helpers

### UI Integration (UltraviolenceUI)

SwiftUI integration components:

- `RenderView`: SwiftUI view for Metal rendering
- `MTKView` integration
- SwiftUI environment bridging

### Support Utilities (UltraviolenceSupport)

Supporting utilities and extensions:

- Metal helpers and extensions
- Error types
- Logging utilities
- Type-safe Metal buffer operations

### Macros (UltraviolenceMacros)

Swift macros for code generation:

- `@UVEntry`: Generates boilerplate for shader parameters
- Automatic struct alignment for Metal-Swift interop

### Examples (UltraviolenceExamples)

Example implementations and demos:

- Sample rendering pipelines
- Shader implementations
- Interaction patterns
- Reusable elements

### Shaders

Metal shader libraries:

- **UltraviolenceExampleShaders**: Common shaders for examples
- **GaussianSplatShaders**: Specialized Gaussian splatting shaders

## Rendering Pipeline

### 1. Setup Phase

The setup phase occurs once when the element tree is built:

```swift
graph.processSetup()
```

- Creates Metal pipeline states
- Allocates buffers
- Loads textures and resources
- Compiles shaders

### 2. Workload Phase

The workload phase executes for each frame:

```swift
graph.processWorkload()
```

- Encodes rendering commands
- Updates uniforms and buffers
- Executes compute kernels
- Performs draw calls

### 3. Element Lifecycle

1. **Element Creation**: Elements are instantiated declaratively
2. **Node Expansion**: Elements expand into nodes in the graph
3. **Setup Processing**: One-time setup operations
4. **Workload Processing**: Per-frame rendering operations
5. **State Updates**: Property changes trigger selective rebuilding


### 4. Environment Propagation

Environment values flow down the element tree:

#### Environment Flow Example

```
RootElement (env: device, commandQueue)
├── RenderPass (env: + renderPassDescriptor)
│   ├── Draw (env: + renderEncoder)
│   │   └── Parameters (env: unchanged)
│   └── Draw (env: + renderEncoder)
└── ComputePass (env: + computeEncoder)
```

#### Key Environment Values

- **Device & Queue**: Set at the root level
- **Command Buffer**: Created per frame
- **Encoders**: Created by pass elements
- **Descriptors**: Modified by modifier elements
- **Custom Values**: User-defined values

### 5. Command Buffer Structure

Command buffers coordinate GPU work:

```
CommandBuffer
├── RenderCommandEncoder (RenderPass)
│   ├── Draw commands
│   └── Parameters/textures
├── ComputeCommandEncoder (ComputePass)
│   └── Dispatch commands
└── BlitCommandEncoder (BlitPass)
    └── Copy operations
```

Handlers can be attached for scheduling and completion events.

## Key Patterns

### Composition

Elements compose to build complex rendering pipelines:

```swift
struct MyScene: Element {
    var body: some Element {
        RenderPass {
            Draw(mesh: teapot)
                .vertexShader(MyVertexShader())
                .fragmentShader(MyFragmentShader())
                .parameters(transforms)
        }
    }
}
```

### Modifiers

Modifiers configure rendering state:

```swift
element
    .renderPipelineDescriptorModifier { descriptor in
        descriptor.isAlphaToCoverageEnabled = true
    }
    .environment(\.cullMode, .back)
```

### Environment Injection

Pass values down the tree:

```swift
ContentView()
    .environment(\.device, metalDevice)
    .environment(\.commandQueue, commandQueue)
```

### Conditional Rendering

Dynamic content based on state:

```swift
var body: some Element {
    if showWireframe {
        WireframeRenderer(mesh: mesh)
    } else {
        SolidRenderer(mesh: mesh)
    }
}
```

## Metal Integration

### Shader Management

The `ShaderLibrary` provides type-safe shader loading:

```swift
let library = ShaderLibrary(bundle: .module)
let vertexShader = try library.function(named: "vertex_main", type: VertexShader.self)
```

### Parameter Binding

Type-safe parameter binding system:

```swift
Parameters(vertex: transforms, fragment: materials)
```

### Resource Management

Automatic resource lifecycle management:

- Textures loaded on demand
- Buffers allocated as needed
- Pipeline states cached and reused

## Threading Model

- **Main Thread**: Element tree updates and state management
- **Render Thread**: Command encoding and submission
- **GPU**: Actual rendering execution

The framework ensures thread safety through:

- `@MainActor` annotations for UI updates
- Synchronized access to shared resources
- Command buffer scheduling

_Note: There are ongoing concurrency safety improvements tracked in [issue #146](https://github.com/schwa/Ultraviolence/issues/146) (Sendable conformance)._

## Performance Considerations

- **Selective Rebuilding**: Only affected parts rebuild when state changes
- **Resource Caching**: Pipeline states and shaders are cached
- **Command Buffer Optimization**: Commands are batched efficiently

## Extension Points

### Custom Elements

Create custom elements by conforming to `Element`:

```swift
struct MyCustomElement: Element {
    var body: some Element {
        // Custom composition
    }
}
```

### Custom BodylessElements

For direct Metal operations:

```swift
struct MyMetalOperation: BodylessElement {
    func workloadEnter(_ node: Node) throws {
        // Encode Metal commands
    }
}
```

### Environment Keys

Add custom environment values:

```swift
extension UVEnvironmentValues {
    var myCustomValue: MyType {
        get { self[MyCustomKey.self] }
        set { self[MyCustomKey.self] = newValue }
    }
}
```

## Best Practices

1. **Keep Elements Small**: Each element should have a single responsibility
2. **Use Composition**: Build complex scenes from simple, reusable elements
3. **Minimize State**: Only use state where necessary for performance
4. **Leverage Environment**: Use environment for cross-cutting concerns
5. **Cache Resources**: Reuse Metal resources when possible
6. **Profile Performance**: Use Metal System Trace to identify bottlenecks

## Comparison with SwiftUI

| Aspect        | SwiftUI          | Ultraviolence          |
| ------------- | ---------------- | ---------------------- |
| Core Protocol | View             | Element                |
| Composition   | Views            | Elements               |
| State         | @State, @Binding | @UVState, @UVBinding   |
| Environment   | @Environment     | @UVEnvironment         |
| Output        | UI Elements      | Metal Commands         |
| Rebuild       | Diffing          | Selective Node Updates |

## Future Directions

- **Mesh Shaders**: Support for Metal 3 mesh shaders ([issue #68](https://github.com/schwa/Ultraviolence/issues/68))
- **Ray Tracing**: Integration with Metal ray tracing ([issue #86](https://github.com/schwa/Ultraviolence/issues/86))
- **Shader Graph**: Visual shader composition ([issue #67](https://github.com/schwa/Ultraviolence/issues/67))
- **Performance Tools**: Built-in profiling and debugging
- **More Platforms**: visionOS and iOS optimization ([issue #82](https://github.com/schwa/Ultraviolence/issues/82))

## Related Documentation

- [README.md](../README.md) - Getting started guide
- [Internals.md](Internals.md) - Internal implementation details and performance
- [CLAUDE.md](../CLAUDE.md) - Development guidelines
- API Documentation - Generated from source
