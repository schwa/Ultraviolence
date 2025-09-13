# Ultraviolence Internals - Current State

## Core Concepts

The framework requires five fundamental features to function:

### 1. Composition
- *What*: Elements can return other elements via `body` property
- *Why*: Enables declarative, hierarchical structure

### 2. State Management (@UVState)
- *What*: Local state that persists across element recreation
- *Why*: UI needs to maintain state between frames

### 3. Environment System (@UVEnvironment)
- *What*: Values propagate down the element tree
- *Why*: Pass Metal objects (device, encoders) and configuration through the tree
- *How*: Each node inherits parent's environment, can modify for children

### 4. Two-Phase Processing (Setup/Workload)
- *What*: Separate on-demand setup from per-frame work
- *Why*: Expensive operations (shader compilation) must run only when needed
- *Setup Phase (On-Demand)*:
  - Runs when: New elements, changed resources, configuration changes, context loss
  - Operations: Pipeline states, shader compilation, resource allocation
  - Should be: Selective based on actual changes
- *Workload Phase (Every Frame)*:
  - Command encoding, uniform updates, draw calls
  - Always runs for active elements
- *Status*: Broken - runs setup every frame due to comparison failure

### 5. Modifiers
- *What*: Chainable modifications to elements (`.modifier().modifier2()`)
- *Why*: Clean API for configuration without subclassing
- *Challenge*: Each modifier wraps the element, often with closures
- *Problems*:
  - No general `ElementModifier` protocol (unlike SwiftUI's `ViewModifier`)
  - Closures make comparison impossible
  - Type erasure loses BodylessElement methods
  - Deep generic nesting

## Three-Phase Update Loop

The framework processes each frame through three distinct phases:

### Phase 1: Update Graph
- *Purpose*: Transform declarative Element tree into Node graph
- *Frequency*: Every frame
- *Operations*: Create elements, expand nodes, compare changes, update state
- *Problem*: Currently marks everything as changed due to closure comparison

### Phase 2: Setup (On-Demand)
- *Purpose*: Prepare resources for new/changed elements
- *Frequency*: Should be only when needed, but currently every frame
- *Operations*: Compile shaders, create pipeline states, allocate resources
- *Problem*: Runs unnecessarily due to Phase 1 false positives

### Phase 3: Workload
- *Purpose*: Encode actual rendering commands
- *Frequency*: Every frame
- *Operations*: Encode commands, update uniforms, issue draw calls
- *Status*: Works correctly

## The Core Problem

All five features work in isolation, but are undermined by one issue:
- Elements are recreated every frame (with new closures)
- Comparison fails (`equalToPrevious()` can't compare closures)
- Everything marked as "changed" in Phase 1
- Setup runs every frame in Phase 2 (including shader compilation)
- Phase 3 works but with unnecessary overhead from Phase 2

The solution (structural identity) would fix this by not comparing element properties at all.

## Current Performance Issues

### Critical Issue: Shader Recompilation Every Frame (#25)

#### Symptoms
- Metal debugger shows "late MTLRenderPipelineState creation" warnings
- Potential frame rate drops (compiling shaders while rendering)

#### Root Cause
The framework currently recreates all element instances every frame, causing:

1. *New Element Instances*: RenderView creates new `CommandBufferElement` and environment modifiers each frame
2. *Failed Equality Checks*: `equalToPrevious()` compares properties using reflection, but:
   - Closures (in `EnvironmentWritingModifier.modify`) are not `Equatable`
   - New instances have different references even if logically identical
3. *Cascade Effect*: When equality check fails, all elements marked as "element changed"
4. *Setup Runs Every Frame*: This triggers `RenderPipeline.setupExit()` which recompiles shaders
5. *Performance Degradation*: Shader compilation is expensive and should happen once, not every frame

#### Example Log Output
```
Drawing frame #12
Marking node as needing setup: CommandBufferElement (element changed)
Marking node as needing setup: RenderPass (element changed)
Marking node as needing setup: RenderPipeline (element changed)
Running setupExit for RenderPipeline (completing setup)  // ← Shader compilation!
```

## The Three-Graph Architecture

Understanding the different graph layers is crucial to solving this problem:

### 1. Element Graph (User's declarative structure)
- *What*: Value types created fresh each frame (`CommandBufferElement`, `RenderPass`, etc.)
- *Problem*: Contains closures, can't be compared for equality
- *Lifecycle*: Recreated entirely each frame via `content()` closure
- *Example*:
  ```swift
  CommandBufferElement {
      RenderPass {
          BillboardRenderPipeline(...)
      }
  }
  ```

### 2. Structural ID Graph (Identity mapping - PROPOSED)
- *What*: Derived from Element Graph position + type + explicit `.id()`
- *Purpose*: Stable identity that persists across frames
- *Example*:
  ```
  [(CommandBufferElement, 0), (RenderPass, 0), (BillboardRenderPipeline, 0)]
  ```
- *Currently*: Doesn't exist yet - this is what we need to build

### 3. Node Graph (Persistent runtime structure)
- *What*: Reference types (`Node` class instances) that persist across updates
- *Contains*:
  - Reference to current element
  - Children nodes
  - State storage (`stateProperties`)
  - Environment values
  - `hasCompletedSetup` flag
- *Problem*: Currently gets its elements replaced every frame, triggering rebuilds

### Current Flow (Broken)
1. User provides Element Graph (values)
2. `expandNode` replaces Node's element references
3. Tries to compare old vs new elements (fails due to closures)
4. Marks everything as needing setup
5. Expensive operations run again

## Additional Findings

### @UVState Change Detection Already Works
Investigation revealed that `@UVState` already has sophisticated change detection:
- State properties are explicitly skipped in `equalToPrevious()` comparison
- When state values change, `StateBox.valueDidChange()` marks dependent nodes for rebuild
- State persists across element recreation via `storeStateProperties()`/`restoreStateProperties()`

The irony: This smart state tracking is undermined by the closure comparison problem.

### Why We Can't Eliminate Closures
Initial thought was to remove closures from `EnvironmentWritingModifier`, but closures are fundamental throughout the API:
- *Element Builders*: `@ElementBuilder content: () throws -> Content`
- *Event Callbacks*: `onCommandBufferScheduled`, `onWorkloadEnter`, etc.
- *Custom Draw Logic*: `Draw(encodeGeometry: @escaping ...)`
- *Modifiers*: All take closures for flexibility

Closures are essential for the declarative API design, lazy evaluation, and capturing context.

### Setup vs Workload

*Setup Phase* (`setupEnter/setupExit`):
- Runs when element is new or explicitly needs setup
- Place expensive operations here:
  - Shader compilation
  - Pipeline state creation
  - Texture loading
  - Buffer allocation

*Workload Phase* (`workloadEnter/workloadExit`):
- Runs every frame
- Keep lightweight:
  - Setting pipeline state
  - Binding resources
  - Draw calls
  - Uniform updates

## Architecture Issues

### Hidden Global Dependency in Environment Access

The framework has an architectural inconsistency in how environment values are accessed during the process phase:

#### The Problem
- `workloadEnter/Exit` and `setupEnter/Exit` methods receive a `node` parameter directly
- However, `@UVEnvironment` property wrappers cannot access this parameter
- Instead, they rely on a global `activeNodeStack` maintained by the System

#### Code Example
```swift
// In process phase - node is passed explicitly
func workloadEnter(_ node: Node) throws {
    // But @UVEnvironment properties inside here use global state:
    // They access System.current?.activeNodeStack.last
    // Not the node parameter passed to this function
}
```

#### Why This Is Problematic
1. **Hidden coupling**: Elements appear to have local access but actually depend on global mutable state
2. **Fragility**: The stack must be perfectly maintained or environment access crashes
3. **Thread safety**: Global mutable state prevents concurrent processing
4. **API dishonesty**: The function signature suggests node is sufficient, but it's not

#### Current Workaround
The System maintains `activeNodeStack` during traversal:
```swift
activeNodeStack.append(node)
defer { activeNodeStack.removeLast() }
try enter(bodylessElement, node)  // node passed but not used for @UVEnvironment
```

#### Potential Solutions
1. **Explicit context**: Pass environment through the node parameter instead of property wrappers
2. **Context object**: Bundle node + environment in a context parameter
3. **Direct access**: Use `node.environment[KeyPath]` instead of `@UVEnvironment` wrapper
4. **Thread-local storage**: Make the stack thread-local to at least enable concurrency

This design prioritizes SwiftUI-like syntax over explicit dependencies, but the benefits are undermined by the global state requirement.

## Related Issues

- *#25*: Graph.updateContent should detect if content changed (core issue)
- *#191*: Fix activeNodeStack assertion failure (revealed this issue)
- *#31*: Bring back _Element (related to element identity)
