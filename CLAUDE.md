# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultraviolence is an experimental declarative framework for Metal rendering in Swift, using a SwiftUI-inspired architecture. It provides a DSL for composing Metal render pipelines declaratively.

## Development Commands

### Build & Test

- **Build**: `swift build`
- **Test**: `swift test`
- **Run specific test**: `swift test --filter TestName`
- **Clean**: `swift package clean`

### Development Workflow

- The project uses Swift Package Manager exclusively (no Xcode project file)
- Requires macOS 15+ and Xcode 16+ with Swift 6.0
- Tests use Swift Testing framework (not XCTest) - use `#expect` assertions and `@Test` attributes

## Architecture Overview

### Core Concepts

The framework follows a **declarative, graph-based rendering pattern**:

1. **Element Protocol**: Core abstraction similar to SwiftUI's View

   - Elements compose through `@ElementBuilder` result builder
   - Each element has a `Body` associated type for composition
   - `BodylessElement` for leaf nodes without children

2. **Graph System**: Central rendering orchestration

   - `Graph` class manages the element tree
   - `Node` objects represent elements in the graph
   - Two-phase rendering: setup phase + workload execution

3. **State Management**: SwiftUI-like state system
   - `@UVState` - Local component state
   - `@UVBinding` - Two-way data binding
   - `@UVObservedObject` - External observable objects
   - `@UVEnvironment` - Environment value injection

### Key Types to Understand

- **Element Types**: `Element`, `BodylessElement`, `AnyElement`
- **Rendering**: `RenderPass`, `ComputePass`, `BlitPass`, `CommandBufferElement`
- **SwiftUI Bridge**: `RenderView` hosts Ultraviolence content in SwiftUI
- **State**: Property wrappers in `Sources/Ultraviolence/Core/PropertyWrappers/`

### Project Structure

```
Sources/
├── Ultraviolence/          # Core framework
│   ├── Core/              # Element system, graph, state management
│   ├── Roots/             # Top-level rendering entry points
│   └── Support/           # Utilities and helpers
├── UltraviolenceUI/       # SwiftUI integration layer
├── UltraviolenceSupport/  # Base utilities, Metal helpers, SIMD extensions
└── UltraviolenceMacros/   # Swift macro implementations
```

## Code Conventions

### Metal Interop

- Ensure identical Swift/Metal struct layout alignment
- Use descriptive Metal attribute names (e.g., `position_in_grid`)
- Always add debug labels to Metal resources
- Use signposting for performance tracking

### Error Handling

- Use descriptive `fatalError()` messages for impossible states
- Prefer throwing functions over silent failures
- Guard early with clear error messages

### Testing

- Write tests using Swift Testing framework
- Use `#expect` for assertions
- Golden image tests for visual validation in `Tests/UltraviolenceTests/GoldenImages/`

## Common Tasks

### Adding a New Element

1. Create element conforming to `Element` or `BodylessElement`
2. Implement required protocol methods
3. Add `@ElementBuilder` support if it has children
4. Consider environment value support if needed

### Debugging Rendering Issues

- Check Metal debug labels and groups
- Use signposting to track performance
- Enable Metal validation layers
- Review graph expansion with debug logging

## Important Notes

- The framework is experimental and actively evolving
- Many TODOs reference GitHub issues for tracking
- The architecture mimics SwiftUI but for Metal rendering
- Performance is critical - avoid unnecessary graph rebuilds
