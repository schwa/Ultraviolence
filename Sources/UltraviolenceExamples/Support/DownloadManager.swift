import Foundation
import SwiftUI

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    @Published var downloadedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var isDownloading = false

    private var downloadTask: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private var downloadedLocation: URL?

    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    func download(from url: URL) async throws -> URL {
        isDownloading = true
        downloadedBytes = 0
        totalBytes = 0

        defer {
            isDownloading = false
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let task = urlSession.downloadTask(with: url)
            self.downloadTask = task
            task.resume()
        }
    }

    func cancel() {
        downloadTask?.cancel()
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            self.downloadedBytes = totalBytesWritten
            self.totalBytes = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : 0
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move to a temporary location since the original will be deleted
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.moveItem(at: location, to: tempURL)
            Task { @MainActor in
                self.continuation?.resume(returning: tempURL)
                self.continuation = nil
            }
        } catch {
            Task { @MainActor in
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            Task { @MainActor in
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
        }
    }
}
