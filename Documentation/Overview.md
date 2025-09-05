# Ultraviolence Overview

## Introduction

Ultraviolence ("UV") is a Swift Package that provides a composable architecture on top of Metal.

UV's design loosely follows SwiftUI. UV Elements correspond to SwiftUI Views, including SwiftUI features like State, Environment, and Bindings (UVState, UVEnvironment, UVBinding). UV does not simplify Metal - you will still need a deep understanding of Metal to use it effectively. However, UV helps you skip many complex Metal setups and boilerplate code. It also enables you to compose multiple Metal render and compute pipelines to create a "render graph."

UV is a "low-level" library rather than a game engine or a high-level graphics library. It provides a foundation for writing your graphics code but does not include a scene graph API or built-in shaders beyond example shaders.

## Design

The basic building block of UV is the rather generically named Element protocol. Instances of Element can be almost anything, and UV provides many concrete Element types to express a Metal workload. Elements are very similar to SwiftUI Views. They have a body property that returns some Elements. The body property is a result builder that allows you to compose multiple elements together.

UV provides several "root" types, representing a render graph's root. You create instances to host the Elements representing your workload and actively run your workload. The two primary roots are RenderView, a SwiftUI view capable of hosting and rendering a render graph life, and OffscreenRenderer, a type capable of running a workload and rendering to an output texture or image.

Many concepts familiar to SwiftUI developers are present in UV. UVState, UVBinding, and UVEnvironment are analogs to SwiftUI's State, Binding, and Environment, respectively, and work similarly. UVEnvironment and its associated modifiers are the key mechanisms for passing data and configuration down the render graph.

## Comparison to Traditional Metal

UV provides a declarative approach to Metal rendering, reducing boilerplate while maintaining full control over the rendering pipeline. The framework handles the complexity of render graph construction and state management, allowing developers to focus on their rendering logic.

## Key Concepts

- **Elements**: The fundamental building blocks, similar to SwiftUI Views
- **State Management**: UVState, UVBinding, and UVEnvironment for data flow
- **Render Graphs**: Composable pipelines for complex rendering workflows
- **Environment Modifiers**: Pass configuration through the element tree

## Current Status

UV is experimental and under active development. The API is not stable and may change significantly. 

### Known Issues and Future Work

- Async support needs improvement
- Modifier system requires refinement
- Performance optimizations needed
- Type safety could be improved (Elements can be combined nonsensically)
- Documentation and examples need expansion

### Future Ideas

- Expose MTLFunctionStitchingGraph into UV for shader graph functionality
- Enhanced scene graph API
- Built-in shader library expansion