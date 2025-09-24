import SwiftUI
import UniformTypeIdentifiers

struct CachingImportButton: View {
    @Binding
    private var url: URL?

    var identifier: String
    var allowedContentTypes: [UTType]

    @State
    private var isImporting = false

    init(url: Binding<URL?>, identifier: String, allowedContentTypes: [UTType]) {
        self._url = url
        self.identifier = identifier
        self.allowedContentTypes = allowedContentTypes
    }

    var body: some View {
        Button("Import") {
            isImporting = true
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: allowedContentTypes) { result in
            if case .success(let url) = result {
                do {
                    url = try CachingImportHelper(identifier: identifier).storeImportedFile(at: url)
                }
                catch {
                    print("Failed to store imported file: \(error)")
                }
            }
        }
        .onChange(of: identifier, initial: true) {
            url = CachingImportHelper(identifier: identifier).storedURL()
        }
    }
}

struct CachingImportWell <Content>: View where Content: View {
    var identifier: String
    var allowedContentTypes: [UTType]
    var content: (URL) -> Content

    @Binding
    private var url: URL?

    @State
    private var isDropTargeted: Bool = false

    init(url: Binding<URL?>, identifier: String, allowedContentTypes: [UTType], content: @escaping (URL) -> Content) {
        self._url = url
        self.identifier = identifier
        self.allowedContentTypes = allowedContentTypes
        self.content = content
    }

    var body: some View {
        Group {
            if let url {
                content(url)
            }
            else {
                ContentUnavailableView("No File", systemImage: "exclamationmark.triangle")
                //                    .onDrop(of: allowedContentTypes, isTargeted: $isDropTargeted) { providers in
                //                        if let provider = providers.first {
                //                            do {
                //                                //self.url = try CachingImportHelper(identifier: identifier).storeImportedFile(at: url)
                //                            }
                //                            catch {
                //                                print("Failed to store imported file: \(error)")
                //                            }
                //                        }
                //                        return false
                //                    }
            }
        }
        .onChange(of: identifier, initial: true) {
            url = CachingImportHelper(identifier: identifier).storedURL()
        }
    }
}

struct CachingImportHelper {
    var identifier: String

    @discardableResult
    private func ensureCachesDirectory() throws -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: cachesDirectory.path, isDirectory: &isDirectory)
        if !(exists && isDirectory.boolValue) {
            try FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: true)
        }
        return cachesDirectory
    }

    func storedURL() -> URL? {
        do {
            let cachesDirectory = try ensureCachesDirectory()
            let fileManager = FileManager.default
            let contents = try? fileManager.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: nil)
            return contents?.first { $0.lastPathComponent.starts(with: identifier) }
        } catch {
            print("Failed to ensure caches directory: \(error)")
            return nil
        }
    }

    func storeImportedFile(at url: URL) throws -> URL {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let cachesDirectory = try ensureCachesDirectory()

        let destinationURL = cachesDirectory.appendingPathComponent("\(identifier).\(url.pathExtension)")
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: url, to: destinationURL)
        return destinationURL
    }
}
