# Ultraviolence Internals

## Core Concepts

The framework requires five fundamental features to function:

### 1. Composition
- **What**: Elements can return other elements via `body` property
- **Why**: Enables declarative, hierarchical structure
- **Challenge**: Recursive tree that terminates at BodylessElements
- **Status**: ✅ Works well

### 2. State Management (@UVState)
- **What**: Local state that persists across element recreation
- **Why**: UI needs to maintain state between frames
- **How**: StateBox stores values on persistent nodes, changes trigger `setNeedsRebuild()`
- **Challenge**: State must survive element recreation each frame
- **Status**: ✅ Works when not undermined by comparison failures

### 3. Environment System (@UVEnvironment)
- **What**: Values propagate down the element tree
- **Why**: Pass Metal objects (device, encoders) and configuration through the tree
- **How**: Each node inherits parent's environment, can modify for children
- **Challenge**: Must flow correctly through all wrapper elements
- **Status**: ✅ Works well

### 4. Two-Phase Processing (Setup/Workload)
- **What**: Separate on-demand setup from per-frame work
- **Why**: Expensive operations (shader compilation) must run only when needed
- **Setup Phase (On-Demand)**: 
  - Runs when: New elements, changed resources, configuration changes, context loss
  - Operations: Pipeline states, shader compilation, resource allocation
  - Should be: Selective based on actual changes
- **Workload Phase (Every Frame)**: 
  - Command encoding, uniform updates, draw calls
  - Always runs for active elements
- **Challenge**: Must accurately track what needs setup vs what can reuse existing setup
- **Status**: ❌ Broken - runs setup every frame due to comparison failure

### 5. Modifiers
- **What**: Chainable modifications to elements (`.modifier().modifier2()`)
- **Why**: Clean API for configuration without subclassing
- **Challenge**: Each modifier wraps the element, often with closures
- **Problems**:
  - No general `ElementModifier` protocol (unlike SwiftUI's `ViewModifier`)
  - Closures make comparison impossible
  - Type erasure loses BodylessElement methods
  - Deep generic nesting
- **Current Approach**: Specific modifier types for specific purposes
- **Status**: ⚠️ Works but causes comparison failures

## Three-Phase Update Loop

The framework processes each frame through three distinct phases:

### Phase 1: Update Graph
- **Purpose**: Transform declarative Element tree into Node graph
- **Frequency**: Every frame
- **Operations**: Create elements, expand nodes, compare changes, update state
- **Problem**: Currently marks everything as changed due to closure comparison

### Phase 2: Setup (On-Demand)
- **Purpose**: Prepare resources for new/changed elements
- **Frequency**: Should be only when needed, but currently every frame
- **Operations**: Compile shaders, create pipeline states, allocate resources
- **Problem**: Runs unnecessarily due to Phase 1 false positives

### Phase 3: Workload
- **Purpose**: Encode actual rendering commands
- **Frequency**: Every frame
- **Operations**: Encode commands, update uniforms, issue draw calls
- **Status**: Works correctly

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
- Severe frame rate drops
- GPU stalls during rendering

#### Root Cause
The framework currently recreates all element instances every frame, causing:

1. **New Element Instances**: RenderView creates new `CommandBufferElement` and environment modifiers each frame
2. **Failed Equality Checks**: `equalToPrevious()` compares properties using reflection, but:
   - Closures (in `EnvironmentWritingModifier.modify`) are not `Equatable`
   - New instances have different references even if logically identical
3. **Cascade Effect**: When equality check fails, all elements marked as "element changed"
4. **Setup Runs Every Frame**: This triggers `RenderPipeline.setupExit()` which recompiles shaders
5. **Performance Degradation**: Shader compilation is expensive and should happen once, not every frame

#### Example Log Output
```
Drawing frame #12
Marking node as needing setup: CommandBufferElement (element changed)
Marking node as needing setup: RenderPass (element changed)
Marking node as needing setup: RenderPipeline (element changed)
Running setupExit for RenderPipeline (completing setup)  // ← Shader compilation!
```

## Proposed Solution: Structural Identity

### The SwiftUI Approach

SwiftUI solves this elegantly using **structural identity**:
- Position in the view tree serves as implicit identity
- Views at the same position are considered the "same" view
- Explicit `.id()` modifier available when position isn't enough
- No expensive property comparison needed

### Proposed StructuralID System

```swift
struct StructuralID: Hashable {
    struct Atom: Hashable {
        var type: ObjectIdentifier   // Element type identity
        var index: Int              // Position among siblings
        var explicit: AnyHashable?  // Optional explicit ID
    }
    var atoms: [Atom]  // Path from root to node
}
```

#### How It Works

1. **Identity = Path + Type**: Each node identified by its path through the tree plus element type
2. **Fast Comparison**: Just compare arrays of small structs (Hashable)
3. **No Property Comparison**: Avoid comparing closures and element properties entirely
4. **Stable Across Frames**: Same structure = same identity = no re-setup

#### Example
```
root (CommandBufferElement, index: 0)
  └── child (RenderPass, index: 0)
       └── child (BillboardRenderPipeline, index: 0)

StructuralID: [(CommandBufferElement, 0), (RenderPass, 0), (BillboardRenderPipeline, 0)]
```

### Benefits

- **No Closure Comparison**: Eliminates the Equatable problem
- **Predictable**: Matches SwiftUI mental model
- **Efficient**: O(path depth) comparison vs O(properties) reflection
- **Stable**: Identity persists across frames if structure unchanged

### Setup vs Workload

**Setup Phase** (`setupEnter/setupExit`):
- Runs when element is new or explicitly needs setup
- Place expensive operations here:
  - Shader compilation
  - Pipeline state creation
  - Texture loading
  - Buffer allocation

**Workload Phase** (`workloadEnter/workloadExit`):
- Runs every frame
- Keep lightweight:
  - Setting pipeline state
  - Binding resources
  - Draw calls
  - Uniform updates


## Implementation Roadmap

### Phase 1: Quick Fix (Current Workaround)
- [x] Add `hasCompletedSetup` flag to nodes
- [x] Check for nodes needing setup after update
- [x] Only run setup on nodes that need it
- [ ] **Problem**: Still recreates elements every frame

### Phase 2: Reduce Closure Usage (Investigation)
- [ ] Investigate replacing closures in `EnvironmentWritingModifier` with keyPath + value storage
- [ ] Identify other modifiers that could avoid closures
- [ ] Evaluate trade-offs (type erasure complexity vs comparison benefits)
- [ ] Prototype closure-free modifiers where feasible

### Phase 3: Structural Identity (Proposed)
- [ ] Implement StructuralID system
- [ ] Replace `equalToPrevious()` with identity comparison
- [ ] Add `.id()` modifier for explicit identity
- [ ] Cache element instances when structure unchanged

### Phase 4: Optimization
- [ ] Incremental graph updates
- [ ] Lazy evaluation of unchanged subtrees

## Related Issues

- **#25**: Graph.updateContent should detect if content changed (core issue)
- **#191**: Fix activeNodeStack assertion failure (revealed this issue)
- **#31**: Bring back _Element (related to element identity)

## Migration Guide

When the structural identity system is implemented:

1. **Most code continues working**: Default behavior uses structural identity
2. **Explicit IDs**: Add `.id()` where you need stable identity across structure changes
3. **Remove Equatable**: No need for complex Equatable implementations
4. **Cache Strategically**: Reuse element instances when appropriate

## Additional Findings

### @UVState Change Detection Already Works
Investigation revealed that `@UVState` already has sophisticated change detection:
- State properties are explicitly skipped in `equalToPrevious()` comparison
- When state values change, `StateBox.valueDidChange()` marks dependent nodes for rebuild
- State persists across element recreation via `storeStateProperties()`/`restoreStateProperties()`

The irony: This smart state tracking is undermined by the closure comparison problem.

### Why We Can't Eliminate Closures
Initial thought was to remove closures from `EnvironmentWritingModifier`, but closures are fundamental throughout the API:
- **Element Builders**: `@ElementBuilder content: () throws -> Content`
- **Event Callbacks**: `onCommandBufferScheduled`, `onWorkloadEnter`, etc.
- **Custom Draw Logic**: `Draw(encodeGeometry: @escaping ...)`
- **Modifiers**: All take closures for flexibility

Closures are essential for the declarative API design, lazy evaluation, and capturing context.

### Confirmed Solution: Structural Identity
Since closures can't be eliminated and can't be compared for equality, structural identity remains the best solution:
- No property comparison needed at all
- Position + type = identity
- Completely sidesteps the closure problem
- Allows `@UVState` change detection to work properly

## The Three-Graph Architecture

Understanding the different graph layers is crucial to solving this problem:

### 1. Element Graph (User's declarative structure)
- **What**: Value types created fresh each frame (`CommandBufferElement`, `RenderPass`, etc.)
- **Problem**: Contains closures, can't be compared for equality
- **Lifecycle**: Recreated entirely each frame via `content()` closure
- **Example**:
  ```swift
  CommandBufferElement {
      RenderPass {
          BillboardRenderPipeline(...)
      }
  }
  ```

### 2. Structural ID Graph (Identity mapping - PROPOSED)
- **What**: Derived from Element Graph position + type + explicit `.id()`
- **Purpose**: Stable identity that persists across frames
- **Example**:
  ```
  [(CommandBufferElement, 0), (RenderPass, 0), (BillboardRenderPipeline, 0)]
  ```
- **Currently**: Doesn't exist yet - this is what we need to build

### 3. Node Graph (Persistent runtime structure)
- **What**: Reference types (`Node` class instances) that persist across updates
- **Contains**: 
  - Reference to current element
  - Children nodes
  - State storage (`stateProperties`)
  - Environment values
  - `hasCompletedSetup` flag
- **Problem**: Currently gets its elements replaced every frame, triggering rebuilds

### Current Flow (Broken)
1. User provides Element Graph (values)
2. `expandNode` replaces Node's element references
3. Tries to compare old vs new elements (fails due to closures)
4. Marks everything as needing setup
5. Expensive operations run again

### Proposed Flow (With Structural ID)
1. User provides Element Graph (values)
2. Build Structural ID for each element based on position
3. Compare Structural IDs (not element properties)
4. Only update nodes where Structural ID changed
5. Preserve `hasCompletedSetup` for unchanged identities

The Node graph is the persistent "skeleton" that maintains state and setup results. The Element graph is the ephemeral "instructions" for what should be there. The Structural ID graph is the "bridge" that lets us match ephemeral elements to persistent nodes without comparing closures.

## Summary

The current performance issue stems from recreating elements every frame and failing equality comparisons due to non-Equatable closures. The proposed structural identity system would solve this by using position and type as identity, similar to SwiftUI. This would eliminate expensive shader recompilation and provide predictable, efficient behavior.
