# Ultraviolence Internals - Proposed Changes

## Executive Summary

We need structural identifier to know which elements are the "same" across frames, allowing us to preserve state and avoid unnecessary setup. However, implementing this requires solving the tree invalidation problem: when an element's properties change, its children might change too, invalidating any pre-built identifier list.

The most practical solution is lazy/incremental traversal (like the current `expandNode`), where we traverse and compare simultaneously. Dependency tracking would be ideal but is infeasible since elements have plain properties (not just `@UVState`) that can't be tracked.

## Prerequisite: Refactor to visit/walk APIs

Before implementing structural identifier, we should refactor the current system to use the Element visit/walk APIs. This separates traversal logic from node management:

**Current:** `expandNode` tightly couples traversal with node creation/updating

**Proposed:**
- Use `element.walk(visitor)` for traversal
- Move node management into a `NodeBuildingVisitor`
- Visitor handles comparison, node creation/updating, environment propagation

**Benefits:**
- Cleaner separation of concerns
- Traversal logic becomes reusable
- Structural identifier becomes just another visitor implementation
- No algorithmic changes, just reorganization

This refactoring preserves current behavior while setting up the infrastructure needed for structural identifier.

## Problem Statement

Elements are recreated every frame with new closures, causing comparison failures and triggering unnecessary setup operations including shader recompilation. This happens because:

1. Elements contain closures that cannot be compared for equality
2. The current system attempts deep property comparison using reflection
3. Without stable identifier, we can't tell if we're comparing the "same" element
4. Every element appears "new" even when at the same structural position
5. Setup operations (shader compilation) run every frame instead of once

## Proposed Solution: Structural Identifier + Element Comparison

Adopt SwiftUI's approach where position + type serves as identifier, while still comparing element properties to detect changes. This is a two-tier system:

1. **Structural Identifier** determines if we're looking at the "same" element across frames
2. **Element Equality** determines if that element's properties have changed

### Core Concept

```swift
struct StructuralIdentifier: Hashable {
    struct Atom: Hashable {
        enum Component: Hashable {
            case index(Int)           // Implicit: position in parent
            case explicit(AnyHashable) // Explicit: .id() modifier
        }
        let typeIdentifier: ElementTypeIdentifier
        let component: Component
    }
    let atoms: [Atom]  // Path from root to element
}
```

Each element's identifier is its path through the tree (type + position at each level). Elements at the same structural position are considered the "same" across frames. Once we know two elements are the "same" (via structural identifier), we can then compare their properties to see if the element is dirty and needs re-setup.

Elements can override their structural identifier using an `.id()` modifier for cases where position alone isn't sufficient (similar to SwiftUI).

TODO: Investigate alternative designs for `StructuralIdentifier`. Instead of array of atoms - keep a parent identifier around.

### Architecture Overview

The system maintains three key data structures:

1. **Array of StructuralIdentifiers** - The complete graph in pre-order traversal
2. **Temporary Element Mapping** - Maps identifiers to element instances (per-frame only)
3. **Persistent Node Storage** - Dictionary mapping identifiers to Nodes (persists across frames)

This eliminates the complex parent/child tree structure in favor of a flat array that naturally represents traversal order.

### How It Works

Each frame:

1. **Traverse** element tree building structural identifiers
2. **Diff** new identifiers against previous frame
3. **Update** nodes based on diff results:
   - Added: Create new nodes, call onAppear
   - Removed: Delete nodes, call onDisappear
   - Unchanged: Keep node, but compare element properties
4. **Check Element Changes** for unchanged identities:
   - Use `equalToPrevious()` to detect property changes
   - Mark dirty elements for setup phase
   - Preserve setup for truly unchanged elements
5. **Execute** setup for dirty nodes, workload for all
6. **Cleanup** temporary mappings, preserve identifiers for next frame

### Critical Issue: Tree Invalidation During Updates

The above flow has a fundamental problem: generating the full identifier tree upfront assumes the tree structure is fixed, but element changes can affect their children.

**The Problem:**
1. We traverse the tree and build a complete list of identifiers
2. We discover element A has changed properties
3. Element A's change means it now produces different children
4. Our identifier list is now invalid - it represents the old tree structure

**Potential Solutions:**

**Option 1: Lazy/Incremental Traversal**
- Don't build the full identifier list upfront
- Traverse and compare simultaneously, depth-first
- When an element changes, immediately re-evaluate its children
- Similar to current solution

**Option 2: Dependency Tracking**

- Track which elements depend on which state
- When state changes, mark dependent subtrees as dirty
- Only re-traverse dirty subtrees
- Similar to swiftui perhaps?

The current `Graph.expandNode` already does something similar to Option 1 - it expands nodes lazily as it traverses. We may need to maintain this approach rather than pre-building the full identifier list.

### Benefits

- **Stable Identifier** - Elements maintain identifier across frames via structure
- **Smart Comparison** - Only compare properties for elements with same identifier
- **Efficient Setup** - Setup only runs when element properties actually change
- **Predictable** - Matches SwiftUI mental model
- **Simple** - Flat array instead of complex tree manipulation

## Open Questions

### Which Traversal Strategy?
Given the tree invalidation issue, we need to decide between:
- Lazy/incremental traversal (like current `expandNode`)
- Two-phase updates with re-traversal
- Immutable snapshots with one-frame delay
- State dependency tracking

### Related GitHub Issues
This design addresses several key issues:
- #193: Implement Structural Identifier System
- #25: Graph.updateContent should detect if content changed
- #107: Compare ids to see if they've changed in expandNode
- #30: ElementModifier not being a true Element (architectural issue)

## Migration Impact

Most code will continue working unchanged:
- Default behavior uses structural identifier automatically
- Use `.id()` for explicit identifier when needed
- Existing `equalToPrevious()` still used for change detection
- State management becomes more predictable

## Appendix

### Additional Ideas
- Make Bodyless elements equatable
- Implement proper ElementModifier protocol similar to SwiftUI's ViewModifier
- Identifier caching for static subtrees
- Future: Dependency-Based Setup

  - SwiftUI doesn't have an explicit "setup" phase. We could adopt this approach:

    - Replace `setupEnter`/`setupExit` with reactive dependency management
    - Track dependencies on resources (shaders, pipeline states, textures)
    - Resource creation becomes lazy and cached based on actual usage
    - Setup operations happen automatically when dependencies change

    This would eliminate the setup/workload distinction, making the framework more declarative.


  ##

### References

#### WWDC Session on SwiftUI Identity
- https://developer.apple.com/videos/play/wwdc2021/10022
- Key concepts:
  - Identity: type + "location"
  - View values are ephemeral, identity is persistent
  - State lifetime = view lifetime

#### Community Resources
- https://tanaschita.com/swiftui-structural-identity/
- https://swiftwithmajid.com/2021/12/09/structural-identity-in-swiftui/
- https://saagarjha.com/blog/2024/02/27/making-friends-with-attributegraph/
