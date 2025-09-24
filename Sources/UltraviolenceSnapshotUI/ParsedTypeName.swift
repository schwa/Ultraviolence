import Foundation

// swiftlint:disable discouraged_optional_collection

/// A parsed representation of a Swift type name
struct ParsedTypeName {
    /// The module/library name (if present)
    let moduleName: String?
    /// The base type name without module prefix or generic parameters
    let typeName: String
    /// The generic parameters (if present), including nested types
    let genericParameters: [Self]?

    /// The original unparsed string
    let original: String

    init(_ typeString: String) {
        self.original = typeString

        // First, separate the base type (with possible module) from generic parameters
        let (baseWithModule, generics) = Self.extractGenerics(from: typeString)

        // Then separate module from type name
        let (module, name) = Self.extractModule(from: baseWithModule)

        self.moduleName = module
        self.typeName = name
        self.genericParameters = generics
    }

    /// Extract generic parameters from a type string
    private static func extractGenerics(from string: String) -> (base: String, generics: [Self]?) {
        guard let genericStart = string.firstIndex(of: "<"),
              let genericEnd = string.lastIndex(of: ">") else {
            return (string, nil)
        }

        let base = String(string[..<genericStart])
        let genericContent = String(string[string.index(after: genericStart)..<genericEnd])

        // Parse the generic parameters (handling nested generics)
        let parameters = parseGenericParameters(genericContent)

        return (base, parameters.isEmpty ? nil : parameters)
    }

    /// Parse comma-separated generic parameters, handling nested generics
    private static func parseGenericParameters(_ content: String) -> [Self] {
        var parameters: [Self] = []
        var currentParam = ""
        var depth = 0

        for char in content {
            if char == "<" {
                depth += 1
                currentParam.append(char)
            } else if char == ">" {
                depth -= 1
                currentParam.append(char)
            } else if char == ",", depth == 0 {
                // This comma separates parameters at the current level
                let trimmed = currentParam.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    parameters.append(Self(trimmed))
                }
                currentParam = ""
            } else {
                currentParam.append(char)
            }
        }

        // Don't forget the last parameter
        let trimmed = currentParam.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            parameters.append(Self(trimmed))
        }

        return parameters
    }

    /// Extract module name from a type string
    private static func extractModule(from string: String) -> (module: String?, name: String) {
        // Find the last dot that's not inside angle brackets
        var lastDotIndex: String.Index?
        var depth = 0

        for (index, char) in string.enumerated().reversed() {
            let stringIndex = string.index(string.startIndex, offsetBy: index)

            if char == ">" {
                depth += 1
            } else if char == "<" {
                depth -= 1
            } else if char == ".", depth == 0 {
                lastDotIndex = stringIndex
                break
            }
        }

        if let dotIndex = lastDotIndex {
            let module = String(string[..<dotIndex])
            let name = String(string[string.index(after: dotIndex)...])
            return (module.isEmpty ? nil : module, name)
        }

        return (nil, string)
    }

    /// Get the full type name with generics but without module
    var nameWithGenerics: String {
        if let generics = genericParameters {
            let genericString = generics.map(\.nameWithGenerics).joined(separator: ", ")
            return "\(typeName)<\(genericString)>"
        }
        return typeName
    }

    /// Get the full type name with module and generics
    var fullName: String {
        let base: String
        if let module = moduleName {
            base = "\(module).\(typeName)"
        } else {
            base = typeName
        }

        if let generics = genericParameters {
            let genericString = generics.map(\.fullName).joined(separator: ", ")
            return "\(base)<\(genericString)>"
        }
        return base
    }
}
