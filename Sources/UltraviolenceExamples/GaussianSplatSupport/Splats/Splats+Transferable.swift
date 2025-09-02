#if os(iOS) || (os(macOS) && !arch(x86_64))
import CoreTransferable

extension Array: @retroactive Transferable where Element == Antimatter15Splat {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .antimatter15Splat) { data in
            data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: Antimatter15Splat.self, Array.init)
            }
        }
        DataRepresentation(importedContentType: .json) { data in
            try JSONDecoder().decode([GenericSplat].self, from: data)
                .map(Antimatter15Splat.init)
        }
    }
}
#endif // os(iOS) || (os(macOS) && !arch(x86_64))
