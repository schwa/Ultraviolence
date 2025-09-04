import SwiftUI

public struct DemoMetadata {
    public let name: String
    public let description: String
    public let keywords: [String]
    public let color: Color
    
    public init(name: String, description: String, keywords: [String] = [], color: Color = .blue) {
        self.name = name
        self.description = description
        self.keywords = keywords
        self.color = color
    }
}

@MainActor
public protocol DemoView: View {
    init()

    static var metadata: DemoMetadata { get }
}

extension DemoView {
    public static var metadata: DemoMetadata {
        let defaultName = "\(type(of: Self.self))"
            .replacingOccurrences(of: ".Type", with: "")
            .replacingOccurrences(of: "DemoView", with: "")
        
        return DemoMetadata(
            name: defaultName,
            description: "No description available",
            keywords: [],
            color: .blue
        )
    }
}
