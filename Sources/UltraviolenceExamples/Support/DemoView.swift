import SwiftUI

@MainActor
public protocol DemoView: View {
    init()

    static var name: String { get }

    static var keywords: [String] { get }

    static var demoDescription: String? { get }
}

extension DemoView {
    public static var name: String {
        "\(type(of: Self.self))"
            .replacingOccurrences(of: ".Type", with: "")
            .replacingOccurrences(of: "DemoView", with: "")
    }

    public static var keywords: [String] {
        []
    }

    public static var demoDescription: String? {
        return nil
    }
}
