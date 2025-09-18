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

    public init() {
    }

    public var body: some View {
        VStack(spacing: 0) {
            RenderView { _, _ in
                if let videoTexture = videoPlayer.currentTexture {
                    try RenderPass {
                        try BillboardRenderPipeline(specifier: .texture2D(videoTexture), flippedY: true)
                    }
                }
            }
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .background(Color.black)

            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(videoURL == nil)

                Button("Load Video") {
                    selectVideo()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .onAppear {
            loadDefaultVideo()
        }
    }

    private func loadDefaultVideo() {
        if let url = Bundle.main.url(forResource: "sample", withExtension: "mov") ??
                     Bundle.main.url(forResource: "sample", withExtension: "mp4") {
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
}
