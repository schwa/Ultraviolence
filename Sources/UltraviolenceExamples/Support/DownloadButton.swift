import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

public struct DownloadButton: View {
    let url: URL
    let destinationName: String
    let onCompletion: ((URL) -> Void)?

    @StateObject
    private var downloadManager = DownloadManager()

    @State
    private var downloadError: Error?

    @State
    private var alreadyDownloaded = false

    public init(url: URL, destinationName: String, onCompletion: ((URL) -> Void)? = nil) {
        self.url = url
        self.destinationName = destinationName
        self.onCompletion = onCompletion
    }

    public var body: some View {
        Group {
            if alreadyDownloaded {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Downloaded")
                        .foregroundColor(.secondary)
                }
            } else if downloadManager.isDownloading {
                VStack(spacing: 8) {
                    ProgressView()
                    if downloadManager.downloadedBytes > 0 {
                        Text(formatBytes(downloadManager.downloadedBytes))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Starting download...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } else {
                Button("Download & Unzip") {
                    Task {
                        await downloadAndUnzip()
                    }
                }
            }
        }
        .onAppear {
            checkIfAlreadyDownloaded()
        }
        .alert("Download Error", isPresented: .constant(downloadError != nil)) {
            Button("OK") {
                downloadError = nil
            }
        } message: {
            if let error = downloadError {
                Text(error.localizedDescription)
            }
        }
    }

    @MainActor
    private func downloadAndUnzip() async {
        downloadError = nil

        do {
            // Get caches directory
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let downloadDirectory = cachesDirectory.appendingPathComponent(destinationName)
            try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)

            // Download to temporary file
            let tempURL = downloadDirectory.appendingPathComponent(UUID().uuidString + ".zip")

            // Use our custom download manager for progress tracking
            let downloadedFileURL = try await downloadManager.download(from: url)

            // Move the downloaded file to our desired location
            try FileManager.default.moveItem(at: downloadedFileURL, to: tempURL)

            // Unzip the file
            let unzipDestination = downloadDirectory.appendingPathComponent("unzipped")
            try FileManager.default.createDirectory(at: unzipDestination, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: tempURL, to: unzipDestination)

            // Clean up zip file
            try FileManager.default.removeItem(at: tempURL)

            // Call completion handler
            await MainActor.run {
                alreadyDownloaded = true
                onCompletion?(unzipDestination)
            }

        } catch {
            await MainActor.run {
                downloadError = error
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    private func checkIfAlreadyDownloaded() {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let downloadDirectory = cachesDirectory.appendingPathComponent(destinationName)
        let unzipDestination = downloadDirectory.appendingPathComponent("unzipped")

        // Check if the unzipped folder exists and has content
        if FileManager.default.fileExists(atPath: unzipDestination.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: unzipDestination, includingPropertiesForKeys: nil)
                if !contents.isEmpty {
                    alreadyDownloaded = true
                    // Call completion handler with existing path
                    onCompletion?(unzipDestination)
                }
            } catch {
                // If we can't read the directory, assume it needs to be downloaded
                alreadyDownloaded = false
            }
        }
    }
}
