# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ultraviolence is an experimental declarative framework for Metal rendering in Swift, similar in architecture to SwiftUI but for Metal rendering pipelines. The framework uses a declarative DSL with Elements (similar to SwiftUI Views) that build up rendering command buffers.

## Build Commands

### Primary Build System
- **Build**: `just build` or `swift build --quiet`
- **Test**: `just test` or `swift test --quiet`
- **Run specific test**: `swift test --filter TestName`
- **Format code**: `just format` (runs SwiftLint and clang-format for Metal files)

### Version Control
- Using Jujutsu (`jj`), not git directly
- Push to main: `just push` (runs build, test, and periphery scan before pushing)

## Architecture

### Core Concepts
- **Element Protocol**: Central abstraction similar to SwiftUI's View protocol. Elements have a `body` property that returns other Elements, forming a declarative tree.
- **BodylessElement**: Elements that perform actual Metal operations rather than composing other elements.
- **Node/Graph System**: Internal representation that expands the Element tree for execution. Handles state management and rebuilding.
- **State Management**: Uses `@UVState` and `@UVObservedObject` property wrappers similar to SwiftUI's state management.

### Module Structure
- **Ultraviolence**: Core framework with Element protocol, state management, and base rendering elements
- **UltraviolenceUI**: SwiftUI integration components 
- **UltraviolenceSupport**: Supporting utilities and extensions
- **UltraviolenceMacros**: Swift macros (uses SwiftSyntax)
- **UltraviolenceExamples**: Example implementations and demos
- **UltraviolenceExampleShaders**: Metal shaders for examples (uses MetalCompilerPlugin)
- **GaussianSplatShaders**: Specialized shaders for Gaussian splatting

### Key Patterns
- Elements compose declaratively like SwiftUI views
- Use `@ElementBuilder` for DSL support
- Property wrappers for state: `@UVState`, `@UVBinding`, `@UVObservedObject`
- Environment values propagate through the element tree
- Modifiers pattern for configuring render pipeline descriptors

## Metal Integration
- Metal shaders are compiled via MetalCompilerPlugin
- Shader libraries are loaded and cached
- Parameter binding system for passing data to shaders
- Support for compute, render, and blit passes

## Testing Approach
- Uses Swift Testing framework (not XCTest)
- Test targets: `UltraviolenceTests`, `UltraviolenceExamplesTests`
- Golden image testing for visual validation

## Code Style
- SwiftLint enforced (configuration in `.swiftlint.yml`)
- Swift 6 language mode
- Metal files formatted with clang-format
- Prefer explicit access control in library targets
- Use `@MainActor` for UI-related code

## Development Tips
- Check existing Elements in `Sources/Ultraviolence/` for patterns before creating new ones
- Metal shader compilation happens automatically via the plugin
- Use `just list` to see all available build commands
- The framework follows SwiftUI patterns - if familiar with SwiftUI, apply similar mental models