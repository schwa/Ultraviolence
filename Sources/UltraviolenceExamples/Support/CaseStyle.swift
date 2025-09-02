internal enum CaseStyle {
    case lowerCamelCase
    case titleCase
}

internal extension StringProtocol {
    var camelCaseToTitleCase: String {
        convertCase(from: .lowerCamelCase, to: .titleCase)
    }

    func convertCase(from inputMode: CaseStyle, to outputMode: CaseStyle) -> String {
        switch (inputMode, outputMode) {
        case (.lowerCamelCase, .titleCase):
            var words: [String] = []
            var currentWord = ""

            for character in self {
                if character.isUppercase {
                    if !currentWord.isEmpty {
                        words.append(currentWord)
                    }
                    currentWord = String(character)
                } else {
                    currentWord.append(character)
                }
            }

            if !currentWord.isEmpty {
                words.append(currentWord)
            }

            return words.map(\.capitalized).joined(separator: " ")

        case (.titleCase, .lowerCamelCase):
            let words = self.split(separator: " ").map { $0.lowercased() }
            guard let firstWord = words.first else { return "" }
            let rest = words.dropFirst().map(\.capitalized)
            return ([firstWord] + rest).joined()

        default:
            return String(self)
        }
    }
}
