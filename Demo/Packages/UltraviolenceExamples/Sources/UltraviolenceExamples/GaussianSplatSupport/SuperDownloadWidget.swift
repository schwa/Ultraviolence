import SwiftUI

internal struct SuperDownloadWidget <Label>: View where Label: View {
    var label: Label

    var callback: (Result<URL, Error>) -> Void

    @State
    private var isPopoverPresented: Bool = false

    @State
    private var recentURLs: [URL] = UserDefaults.standard.urls(forKey: "recentDownloads")

    @State
    private var url: URL?

    @State
    private var downloading: Bool = false

    @Environment(\.superdownloadWidgetBookmarks)
    var bookmarks

    init(label: () -> Label, callback: @escaping (Result<URL, Error>) -> Void) {
        self.label = label()
        self.callback = callback
    }

    var body: some View {
        Button(action: { isPopoverPresented.toggle() }, label: { label })
            .popover(isPresented: $isPopoverPresented) {
                Form {
                    if downloading {
                        VStack {
                            ProgressView()
                            Text("Downloading…")
                        }
                    }
                    else {
                        TextField("URL", value: $url, format: .url)
                        Button("Download") {
                            Task {
                                let url = url
                                self.url = nil
                                try! await download(url: url!)
                            }
                        }
                        .disabled(url == nil)
                        Section("Bookmarks") {
                            VStack {
                                ForEach(bookmarks, id: \.self) { url in
                                    Button(url.lastPathComponent) {
                                        Task {
                                            try! await download(url: url)
                                        }
                                    }
                                    #if os(macOS)
                                    .buttonStyle(.link)
                                    #endif
                                }
                            }
                        }
                        Section("Recent Downloads") {
                            VStack {
                                ForEach(recentURLs, id: \.self) { url in
                                    Button(url.lastPathComponent) {
                                        callback(.success(url))
                                    }
                                    #if os(macOS)
                                    .buttonStyle(.link)
                                    #endif
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 320, minHeight: 240)
                .padding()
            }
    }

    func download(url: URL) async throws {
        downloading = true
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let (localUrl, _) = try await session.download(for: request)
        let fileManager = FileManager()
        let destination = try fileManager.applicationSpecificCachesDirectory.appendingPathComponent(url.lastPathComponent)
        print(destination)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: localUrl, to: destination)
        if !recentURLs.contains(destination) {
            recentURLs.append(destination)
        }

        UserDefaults.standard.set(recentURLs, forKey: "recentDownloads")
        Task {
            await MainActor.run {
                callback(.success(destination))
                downloading = false
            }
        }
    }
}

extension SuperDownloadWidget where Label == Text {
    init (_ title: String, callback: @escaping (Result<URL, Error>) -> Void) {
        self.init(label: { Text(title) }, callback: callback)
    }
}

extension FileManager {
    var applicationSupportDirectory: URL {
        get throws {
            let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first.orFatalError()
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        }
    }
    var applicationSpecificSupportDirectory: URL {
        get throws {
            let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first.orFatalError().appendingPathComponent(Bundle.main.bundleIdentifier!)
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        }
    }
    var cachesDirectory: URL {
        get throws {
            let url = urls(for: .cachesDirectory, in: .userDomainMask).first.orFatalError()
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        }
    }
    var applicationSpecificCachesDirectory: URL {
        get throws {
            let url = urls(for: .cachesDirectory, in: .userDomainMask).first.orFatalError().appendingPathComponent(Bundle.main.bundleIdentifier!)
            try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        }
    }
}

extension UserDefaults {
    func urls(forKey key: String) -> [URL] {
        (object(forKey: key) as? [String] ?? []).map { URL(string: $0)! }
    }

    func set(_ urls: [URL], forKey key: String) {
        set(urls.map(\.absoluteString), forKey: key)
    }
}
