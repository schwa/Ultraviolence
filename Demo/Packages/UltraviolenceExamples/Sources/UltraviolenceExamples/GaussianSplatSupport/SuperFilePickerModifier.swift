import SwiftUI

internal struct SuperFilePickerModifier <T>: ViewModifier where T: Transferable & Sendable {
    @State
    private var isDropTargeted: Bool = false

    @State
    private var isFileImporterPresented: Bool = false

    var callback: (Result<[T], Error>) throws -> Void

    init(callback: @escaping (Result<[T], Error>) throws -> Void) {
        self.callback = callback
    }

    func body(content: Content) -> some View {
        content
            .border(Color.blue, width: isDropTargeted ? 5 : 0)
            .toolbar {
                Button("Open…") {
                    isFileImporterPresented = true
                }
            }
            .dropDestination(for: T.self) { items, _ in
                do {
                    try callback(.success(items))
                    return true
                } catch {
                    return false
                }
            }
            isTargeted: { isTargeted in
                isDropTargeted = isTargeted
            }
            .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: T.importedContentTypes()) { result in
                switch result {
                case .success(let url):
                    Task {
                        do {
                            let items = try await T(importing: url, contentType: nil)
                            try callback(.success([items]))
                        }
                        catch {
                            _ = try? callback(.failure(error))
                        }
                    }
                case .failure(let error):
                    _ = try? callback(.failure(error))
                }
            }
    }
}
