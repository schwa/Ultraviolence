import SwiftUI

struct GLTFFilePickerView: View {
    let files: [URL]
    @Binding var selectedURL: URL?
    @Binding var isPresented: Bool

    @State private var searchText = ""

    var filteredFiles: [URL] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List(filteredFiles, id: \.self) { fileURL in
                Button(action: {
                    selectedURL = fileURL
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: fileURL.pathExtension.lowercased() == "glb" ? "cube.fill" : "doc.text.fill")
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading) {
                            Text(fileURL.lastPathComponent)
                                .font(.headline)

                            Text(relativePath(for: fileURL))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let fileSize = fileSize(for: fileURL) {
                            Text(fileSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search files")
            .navigationTitle("Select GLTF/GLB File")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func relativePath(for url: URL) -> String {
        let components = url.pathComponents
        // Find "glTF-Sample-Assets" and show path from there
        if let gltfIndex = components.firstIndex(where: { $0.contains("glTF-Sample-Assets") }) {
            let relevantComponents = components.dropFirst(gltfIndex + 1).dropLast()
            return relevantComponents.joined(separator: "/")
        }
        return url.deletingLastPathComponent().lastPathComponent
    }

    private func fileSize(for url: URL) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: size)
            }
        } catch {
            return nil
        }
        return nil
    }
}
