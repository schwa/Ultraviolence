import AVFoundation
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct VideoPlaybackDemoView: View {
    @State
    private var device = _MTLCreateSystemDefaultDevice()

    @StateObject
    private var videoPlayer = VideoTexturePipeline(device: _MTLCreateSystemDefaultDevice())

    @State
    private var isPlaying = false

    @State
    private var videoURL: URL?

    @State
    private var errorMessage: String?

    @State
    private var enableVCR = true

    @State
    private var vcrParameters = VCRParameters()

    @State
    private var distortedTexture: MTLTexture?

    public init() {
    }

    public var body: some View {
        VStack(spacing: 0) {
            RenderView { context, _ in
                if let videoTexture = videoPlayer.currentTexture {
                    if enableVCR, let distortedTexture = getOrCreateDistortedTexture(for: videoTexture) {
                        // Apply VCR distortion
                        try ComputePass {
                            try VCRDistortionPipeline(
                                inputTexture: videoTexture,
                                outputTexture: distortedTexture,
                                parameters: vcrParameters,
                                frameUniforms: context.frameUniforms
                            )
                        }

                        // Render the distorted texture
                        try RenderPass {
                            try BillboardRenderPipeline(specifier: .texture2D(distortedTexture), flippedY: true)
                        }
                    } else {
                        // Render original video without effects
                        try RenderPass {
                            try BillboardRenderPipeline(specifier: .texture2D(videoTexture), flippedY: true)
                        }
                    }
                }
            }
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .background(Color.black)

            // Controls
            VStack {
                HStack {
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    }
                    .disabled(videoURL == nil)

                    Button("Load Video") {
                        selectVideo()
                    }

                    Toggle("VCR Effects", isOn: $enableVCR)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                if enableVCR {
                    // VCR Effect Controls
                    GroupBox("VCR Settings") {
                        VStack {
                            HStack {
                                Button("Set All to Zero") {
                                    vcrParameters.curvature = 0
                                    vcrParameters.skip = 0
                                    vcrParameters.imageFlicker = 0
                                    vcrParameters.vignetteFlickerSpeed = 0
                                    vcrParameters.vignetteStrength = 0
                                    vcrParameters.smallScanlinesSpeed = 0
                                    vcrParameters.smallScanlinesProximity = 0
                                    vcrParameters.smallScanlinesOpacity = 0
                                    vcrParameters.scanlinesOpacity = 0
                                    vcrParameters.scanlinesSpeed = 0
                                    vcrParameters.scanlineThickness = 0
                                    vcrParameters.scanlinesSpacing = 0
                                    vcrParameters.noiseAmount = 0
                                    vcrParameters.chromaticAberration = 0
                                }
                                Spacer()
                            }
                            HStack {
                                Text("Curvature")
                                Slider(value: $vcrParameters.curvature, in: 0...10)
                                    .frame(width: 200)
                                    .help("CRT screen curvature distortion - warps the image edges")
                                Text(String(format: "%.2f", vcrParameters.curvature))
                            }
                            HStack {
                                Text("Tracking")
                                Slider(value: $vcrParameters.skip, in: 0...1)
                                    .frame(width: 200)
                                    .help("VHS tracking error - horizontal image shifting/glitching")
                                Text(String(format: "%.2f", vcrParameters.skip))
                            }
                            HStack {
                                Text("Flicker")
                                Slider(value: $vcrParameters.imageFlicker, in: 0...2)
                                    .frame(width: 200)
                                    .help("Brightness pulsing - simulates unstable video signal")
                                Text(String(format: "%.2f", vcrParameters.imageFlicker))
                            }
                            HStack {
                                Text("Scanlines")
                                Slider(value: $vcrParameters.scanlinesOpacity, in: 0...2)
                                    .frame(width: 200)
                                    .help("CRT scanline visibility - horizontal lines across screen")
                                Text(String(format: "%.2f", vcrParameters.scanlinesOpacity))
                            }
                            HStack {
                                Text("Vignette")
                                Slider(value: $vcrParameters.vignetteStrength, in: 0...2)
                                    .frame(width: 200)
                                    .help("Screen edge darkening - simulates CRT tube limitations")
                                Text(String(format: "%.2f", vcrParameters.vignetteStrength))
                            }
                            HStack {
                                Text("Noise")
                                Slider(value: $vcrParameters.noiseAmount, in: 0...2)
                                    .frame(width: 200)
                                    .help("Video static/grain - animated noise overlay")
                                Text(String(format: "%.2f", vcrParameters.noiseAmount))
                            }
                            HStack {
                                Text("Color Shift")
                                Slider(value: $vcrParameters.chromaticAberration, in: 0...2)
                                    .frame(width: 200)
                                    .help("RGB channel separation - color fringing at edges")
                                Text(String(format: "%.2f", vcrParameters.chromaticAberration))
                            }
                            HStack {
                                Text("Vignette Pulse")
                                Slider(value: $vcrParameters.vignetteFlickerSpeed, in: 0...2)
                                    .frame(width: 200)
                                    .help("Vignette brightness pulsing speed")
                                Text(String(format: "%.2f", vcrParameters.vignetteFlickerSpeed))
                            }
                            HStack {
                                Text("Scanline Speed")
                                Slider(value: $vcrParameters.scanlinesSpeed, in: 0...2)
                                    .frame(width: 200)
                                    .help("Scanline movement speed")
                                Text(String(format: "%.2f", vcrParameters.scanlinesSpeed))
                            }
                            HStack {
                                Text("Scanline Thickness")
                                Slider(value: $vcrParameters.scanlineThickness, in: 0...1)
                                    .frame(width: 200)
                                    .help("Thickness of scanlines")
                                Text(String(format: "%.2f", vcrParameters.scanlineThickness))
                            }
                            HStack {
                                Text("Scanline Spacing")
                                Slider(value: $vcrParameters.scanlinesSpacing, in: 0...2)
                                    .frame(width: 200)
                                    .help("Distance between scanlines")
                                Text(String(format: "%.2f", vcrParameters.scanlinesSpacing))
                            }
                            HStack {
                                Text("Fast Scanlines")
                                Slider(value: $vcrParameters.smallScanlinesOpacity, in: 0...2)
                                    .frame(width: 200)
                                    .help("Small, fast-moving scanline opacity")
                                Text(String(format: "%.2f", vcrParameters.smallScanlinesOpacity))
                            }
                            HStack {
                                Text("Fast Scanline Speed")
                                Slider(value: $vcrParameters.smallScanlinesSpeed, in: 0...2)
                                    .frame(width: 200)
                                    .help("Speed of small scanlines")
                                Text(String(format: "%.2f", vcrParameters.smallScanlinesSpeed))
                            }
                            HStack {
                                Text("Fast Scanline Density")
                                Slider(value: $vcrParameters.smallScanlinesProximity, in: 0...2)
                                    .frame(width: 200)
                                    .help("Density of small scanlines")
                                Text(String(format: "%.2f", vcrParameters.smallScanlinesProximity))
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadDefaultVideo()
        }
    }

    private func loadDefaultVideo() {
        if let url = Bundle.module.url(forResource: "sample", withExtension: "mov") ??
                     Bundle.module.url(forResource: "sample", withExtension: "mp4") {
            loadVideo(url: url)
        } else {
            errorMessage = "No default video found. Click 'Load Video' to select one."
        }
    }

    private func loadVideo(url: URL) {
        do {
            try videoPlayer.loadVideo(url: url, loopStart: 0, loopEnd: .infinity)
            videoURL = url
            errorMessage = nil
            videoPlayer.play()
            isPlaying = true
        } catch {
            errorMessage = "Failed to load video: \(error.localizedDescription)"
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            videoPlayer.pause()
        } else {
            videoPlayer.play()
        }
        isPlaying.toggle()
    }

    private func selectVideo() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            loadVideo(url: url)
        }
        #else
        errorMessage = "File selection not implemented on iOS"
        #endif
    }

    private func getOrCreateDistortedTexture(for videoTexture: MTLTexture) -> MTLTexture? {
        if distortedTexture == nil || distortedTexture?.width != videoTexture.width || distortedTexture?.height != videoTexture.height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: videoTexture.pixelFormat,
                width: videoTexture.width,
                height: videoTexture.height,
                mipmapped: false
            )
            descriptor.usage = [.shaderRead, .shaderWrite]
            distortedTexture = device.makeTexture(descriptor: descriptor)
            distortedTexture?.label = "VCR Distorted Texture"
        }
        return distortedTexture
    }
}
