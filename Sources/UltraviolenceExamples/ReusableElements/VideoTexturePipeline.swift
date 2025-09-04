import AVFoundation
import Metal
import CoreVideo
import Ultraviolence
import UltraviolenceSupport
import Combine

/// Pipeline that renders video frames to a Metal texture
public class VideoTexturePipeline: ObservableObject {
    private let device: MTLDevice
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var updateTimer: Timer?
    
    @Published public private(set) var currentTexture: MTLTexture?
    private var textureCache: CVMetalTextureCache?
    
    public init(device: MTLDevice) {
        self.device = device
        
        // Create texture cache for efficient video frame conversion
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        self.textureCache = cache
    }
    
    public func loadVideo(url: URL, loopStart: TimeInterval = 2.95, loopEnd: TimeInterval = 11.95) throws {
        // Create player item and player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Configure video output for Metal textures
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        playerItem?.add(videoOutput!)
        
        // Set up looping
        player?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Store loop points
        self.loopStart = CMTime(seconds: loopStart, preferredTimescale: 600)
        self.loopEnd = CMTime(seconds: loopEnd, preferredTimescale: 600)
    }
    
    private var loopStart = CMTime.zero
    private var loopEnd = CMTime.zero
    
    @objc private func playerItemDidReachEnd() {
        player?.seek(to: loopStart)
    }
    
    public func play() {
        player?.play()
        
        // Set up timer for frame updates (60 fps)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.updateFrame()
        }
    }
    
    public func pause() {
        player?.pause()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateFrame() {
        guard let videoOutput = videoOutput,
              let player = player else { return }
        
        let currentTime = player.currentTime()
        
        // Check for loop point
        if currentTime >= loopEnd {
            player.seek(to: loopStart)
            return
        }
        
        // Get the current video frame
        guard videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else {
            return
        }
        
        // Convert pixel buffer to Metal texture
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            nil,
            textureCache!,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )
        
        guard status == kCVReturnSuccess,
              let cvTexture = cvTexture,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            return
        }
        
        texture.label = "Video Frame Texture"
        currentTexture = texture
    }
    
    deinit {
        updateTimer?.invalidate()
        player?.pause()
    }
}