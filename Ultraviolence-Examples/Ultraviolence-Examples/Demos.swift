import DemoKit
import SwiftUI
import UltraviolenceExamples

@MainActor let allDemos: [any DemoView.Type] = {
    var demos: [any DemoView.Type] = [
        EmptyView.self,
        BlinnPhongDemoView.self,
        SkyboxDemoView.self,
        TriangleDemoView.self,
        ComputeDemoView.self,
        DepthDemoView.self,
        MetalFXDemoView.self,
        MixedDemoView.self,
        BouncingTeapotsDemoView.self,
        StencilDemoView.self,
        LUTDemoView.self,
        GameOfLifeDemoView.self,
        AppleEventLogoDemoView.self,
        ColorAdjustDemoView.self,
        DebugShadersDemoView.self,
        PBRDemoView.self,
        SDFDemoView.self,
        PointCloudDemoView.self,
        ParticleEffectsDemoView.self,
        VideoPlaybackDemoView.self,
        PanoramaDemoView.self,
        WireframeDemoView.self
    ]

    #if os(macOS)
    demos += [
        OffscreenDemoView.self
    ]
    #endif

    #if os(iOS)
    demos += [
        ARKitDemoView.self
    ]
    #endif
    return demos
}()

extension EmptyView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Empty", description: "An empty view.")
    }
}

extension TriangleDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Triangle", description: "Basic triangle rendering with animated colors and performance metrics", group: "Basic", keywords: ["animated"])
    }
}

extension GameOfLifeDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Game of Life", description: "Conway's Game of Life cellular automaton simulation using GPU compute shaders", group: "Basic", keywords: ["animated"])
    }
}

extension StencilDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Stencil Buffer", description: "Stencil buffer masking demonstration with checkerboard pattern clipping", group: "Basic", keywords: [])
    }
}

extension ComputeDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Compute", description: "Simple compute shader that copies data between GPU buffers", group: "Basic", keywords: ["needs-work"])
    }
}

extension DepthDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Depth Buffer", description: "Demonstrates rendering depth buffer to texture. It also shows how to use customisable private functions.", group: "Complex", keywords: [])
    }
}

extension MetalFXDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "MetalFX Upscaling", description: "Image upscaling using MetalFX spatial upsampling for enhanced image quality", group: "Basic", keywords: ["metalfx", "needs-work"])
    }
}

extension BouncingTeapotsDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Bouncing Teapots", description: "Physics simulation of animated teapots with MetalFX upscaling and instanced rendering", group: "Complex", keywords: ["metalfx", "animated", "multipass"])
    }
}

extension BlinnPhongDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Blinn-Phong Lighting", description: "3D lighting demonstration using the Blinn-Phong shading model with animated lights", group: "Basic", keywords: ["lighting", "multipass", "animated"])
    }
}

extension SkyboxDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Skybox", description: "Environment mapping demonstration using cube textures for 360-degree backgrounds", group: "Basic", keywords: [])
    }
}

extension AppleEventLogoDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Apple Event Logo", group: "Complex", keywords: ["needs-work", "animated", "video"])
    }
}

extension LUTDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "LUT Color Grading", description: "Color grading and correction using Look-Up Tables (LUTs) for cinematic effects", group: "Basic", keywords: ["post-processing"])
    }
}

#if os(macOS)
extension OffscreenDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Offscreen Rendering", description: "Render-to-texture demonstration showing offscreen rendering capabilities", group: "Basic", keywords: ["needs-work"])
    }
}
#endif

extension MixedDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Mixed Techniques", description: "Combination of multiple rendering techniques including lighting and animation", group: "Complex", keywords: ["multipass", "animated"])
    }
}

extension ColorAdjustDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "ColorAdjustDemoView", description: "TODO", group: "In-progress", keywords: [])
    }
}

extension DebugShadersDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Debug Shaders", description: "Shader debugging visualization with various modes including normals, UV coordinates, depth, wireframe, and distance fields", group: "Basic", keywords: [])
    }
}

extension PBRDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "PBR Rendering", description: "Physically Based Rendering with multiple material presets, environment reflections, and animated lighting", group: "* Broken", keywords: [])
    }
}

extension SDFDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "SDF Raymarching", description: "Real-time signed distance field raymarching with animated shapes, smooth blending, and dynamic lighting", group: "Complex", keywords: ["animated", "raymarching"])
    }
}

extension PointCloudDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Point Cloud", description: "Interactive point cloud visualization with thousands of colored points arranged in a torus shape", group: "Basic", keywords: ["points", "interactive"])
    }
}

extension ParticleEffectsDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Particle Effects", description: "GPU-accelerated particle system with compute shaders featuring various emitter types like fountains, explosions, and fireworks", group: "Complex", keywords: ["compute", "animated"])
    }
}

extension VideoPlaybackDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Video Playback", description: "Full screen video playback with streaming textures rendered through billboard pipeline", group: "Basic", keywords: ["video", "billboard"])
    }
}

extension PanoramaDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "360° Panorama", description: "Interactive 360-degree panoramic photo viewer with spherical projection and WorldView rotation", group: "Basic", keywords: [])
    }
}

extension WireframeDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "Wireframe Teapot", description: "Wireframe demo", group: "Basic", keywords: [])
    }
}

#if os(iOS)
extension ARKitDemoView: @retroactive DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(name: "ARKit Demo", description: "TODO", group: "WIP", keywords: [])
    }
}
#endif
