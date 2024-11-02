# [Ultraviolence](https://github.com/schwa/Ultraviolence)

A declarative framework for Metal rendering in Swift.

## Problem Statement

Metal is an incredibly powerful API but has a reputation for being challenging to work with. This is mainly because it is a low-level API requiring heaps of boilerplate code to get something basic up and running. On the other hand, frameworks like SceneKit and RealityKit offer high-level abstractions that simplify 3D rendering but can be limiting when you need more control.

Ultraviolence (just a placeholder name for now) will aim to strike a balance between these extremes. It will provide a declarative, SwiftUI-inspired API that will be easy to use while giving you low-level control when needed.

### Time to First Teapot

If you have ever looked at Apple’s Metal sample code or used the Metal templates in Xcode, you will probably have noticed that about 95% of the code will be boilerplate every Metal app needs just to get started. Ultraviolence will aim to cut out most, if not all, of that boilerplate so you can focus on what will really matter: your rendering code. Possible example:

```swift
import SwiftUI
import Ultraviolence

struct ContentView: View {
    var body: some View {
        RenderView {
            Draw([Teapot()]) {
                BlinnPhongShader(SimpleMaterial(color: .pink))
            }
            .camera(PerspectiveCamera())
        }
    }
}
```

### Composable Render Passes

Combining shaders in interesting ways is a common task in 3D rendering. Taking inspiration from how easy it is to compose views in SwiftUI, Ultraviolence will let you effortlessly combine render passes. You will be able to experiment with different passes and create reusable components that can be mixed and matched to achieve unique effects.

```swift
struct MyRenderPass: RenderPass {
    @RenderState var downscaled: Texture
    @RenderState var upscaled: Texture

    var body: some RenderPass {
        Chain {
            Draw([Teapot()]) {
                BlinnPhongShader(SimpleMaterial(color: .pink))
            }
            .camera(PerspectiveCamera())
                .renderTarget(downscaled)
            MetalFXUpscaler(input: downscaled)
                .renderTarget(upscaled)
            Blit(input: upscaled)
        }
    }
}
```

### It’s the Shaders, Stupid

In any Metal project, the real action happens in the shaders. But even getting a simple shader up and running requires wading through a lot of setup code. SceneKit and RealityKit often limit what you can do with shaders, and accessing them isn't straightforward. Ultraviolence will make writing and managing your shaders easy, giving you full control over your rendering pipeline.

This example shows how to use shaders and shader parameters in Ultraviolence. Note that you should generally not define your shaders as strings in your code.

```swift
struct MyView: View {
    let source = """
        #include <metal_stdlib>

        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]], constant float4x4& modelViewProjection [[buffer(0)]]) {
            return VertexOut { modelViewProjection * in.position };
        }

        [[fragment]] float fragment_main() {
            return float4(1.0, 0.0, 0.0, 1.0);
        }
    """
        var modelViewProjection: simd_float4x4

        var body: some View {
            RenderView {
                Draw([Teapot()]) {
                    VertexShader(name: "vertex_main", source: source)
                    .parameter("modelViewProjection", modelViewProjection)
                    FragmentShader(name: "fragment_main", source: source)
                }
            }
        }
    }
}
```

TODO: What the above example doesn't show is how to link the vertex descriptor of the geometry to the vertex shader.

### Mixing Compute and Graphics

The following example shows how to mix compute and graphics passes in Ultraviolence.

```swift
struct MyRenderPass: RenderPass {
    var geometries: [Geometry]
    var color: Texture
    var depth: Texture

    var body: some RenderPass {
        Chain {
            Draw(geometries) {
                MyGraphicsShader()
            }
            .colorAttachment(color, index: 0)
            .depthAttachment(depth)
            .depthCompare(.less)

            Compute {
                EdgeDetectionKernel()
            }
            .arguments("color", color)
            .arguments("depth", depth)
            .output(color)
        }
    }
}
```

### Attachments

TODO: Different parts of the rendering pipeline must read and write to different textures or with different parameters. Ultraviolence will need to make it easy to manage these attachments flexibly and conveniently.

### (Some) Batteries Included

Ultraviolence will come with default shaders and utilities to help you get started quickly. While it won’t aim to include every feature, it will provide enough tools to cover common use cases, allowing you to focus on building your unique rendering logic.

List of potential "extra" features:

* Perspective and orthographic cameras
* Unlit shader
* Easy `blit` shaders
* Debug shaders
* Grid shader
* Teapot and basic geometry
* (Basic)ARKit integration (enough to easily place a teapot on your desk)

### Performance

Ultraviolence should not be significantly slower than writing Metal code by hand. The number of Metal commands generated should be the same as those generated by hand. Render graphs that do not change between frames should be fast to "replay".

## Misc Notes/Questions/Problems

- [ ] Get help (literally and metaphorically)
- [ ] `render` could become be a more generic `visit`
- [X] Uniforms.
- [X] Use internal imports for own packages. https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md#declaring-the-access-level-of-an-imported-module
- This is going to overlap with RenderKit. Is this RenderKit4 (are we really up to 4 semi-unreleased projects now?)
- Is `RenderPass` the right name for a node in the graph here. Some nodes are definitely not render passes and it seems too specific. Maybe just `Node` (`RenderNode?`, `RenderElement`?).
- How do we detect state changes and detect if a graph has changed? Adopt ideas from SwiftUI and [ObjcIO](http://objc.io) folks.
- How do we make sure inputs and outputs to shaders are compatible? Can we generate a vertex descriptor from a shader (or vice versa?).
- Cross platform? Crazy idea: Ultraviolence is not necessarily intrinsically tied to Metal. Could we have a Vulkan backend?
- Should Ultraviolence include a scene graph? _Maybe_. A ForEach() operator could be used as a bridge between a render pass and a scene graph. As long as the scene graph can generate an iterable collection of _things_ to draw it can be passed into an Ultraviolence draw. It should be a lot less integrated than in RenderKit2.
- Modern Swift - Metal is not very Swift Concurrency friendly.
- It should be easy to capture debugging.
- Offscreen rendering:

```swift
func render() {
    let renderer = Renderer {
          Draw([Teapot()]) {{
              BlinnPhongShader(SimpleMaterial(color: .pink))
          }
          .camera(PerspectiveCamera())}
    }
    let image = try renderer.render(size: [1600, 1200]).cgImage
    ...
}
```

- Efficiency is going to be very very tough to make 100% solid.
- SwiftUI View's can be composed arbitrarily and still produce valid (if weird) UI. Ultraviolence can't allow that - it doesn't make sense to make a Draw() node without shaders, or a Draw() node with multiple vertex shaders... Arbitrary composition isn't going to work everywhere. We may need a more expressive type system to enforce this.
- The render command is really used to build a graph of commands. The graph can be inspected and reasoned with - for example Draw nodes need to make sure there is a vertex shader and a fragment shader and geometry. Is it possible to guarantee the graph is correct at compile time (goes with previous note
- Wrap Metal types as much as possible. This allows us to get better type and concurrency safety (e.g. Buffer<Type>/RawBuffer vs MTLBuffer etc).
- What do with types that overlap naming with SwiftUI State/ForEach etc.
