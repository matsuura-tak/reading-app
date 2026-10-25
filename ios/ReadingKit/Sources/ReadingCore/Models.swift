import Foundation

public enum BookStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case current
    case reading
    case tsundoku
    case finished
    case paused

    public nonisolated var isCurrentReading: Bool {
        self == .current || self == .reading
    }
}

public enum ProgressUnit: String, Codable, Sendable, CaseIterable, Equatable {
    case page
    case location
    case percent
}

public enum AppearanceID: String, Codable, Sendable, CaseIterable, Equatable {
    case `default` = "default"
    case dark = "dark"
    case light = "light"
    case kinari = "kinari"
    case sumi = "sumi"
    case shu = "shu"

    public nonisolated var isPlusTheme: Bool {
        switch self {
        case .kinari, .sumi, .shu:
            return true
        case .default, .dark, .light:
            return false
        }
    }

    public nonisolated static func resolve(_ rawValue: String?) -> AppearanceID {
        guard let rawValue, let value = AppearanceID(rawValue: rawValue) else {
            return .default
        }
        return value
    }
}

public enum EntrySource: String, Codable, Sendable, CaseIterable, Equatable {
    case barcode
    case search
    case ocr
    case manual
    case recommendation
}

public enum StartedBy: String, Codable, Sendable, CaseIterable, Equatable {
    case tap
    case widget
    case shortcut
    case control
}

public enum SessionState: String, Codable, Sendable, CaseIterable, Equatable {
    case idle
    case active
    case paused
    case prompting
}

public enum RecommendationAxis: String, Codable, Sendable, CaseIterable, Equatable {
    case readers
    case nextVolume
    case sameAuthor
    case sameAward
    case sameLabel

    /// Default priority order (1 = highest, 5 = lowest).
    public nonisolated var defaultPriorityRank: Int {
        switch self {
        case .readers: return 1
        case .nextVolume: return 2
        case .sameAuthor: return 3
        case .sameAward: return 4
        case .sameLabel: return 5
        }
    }
}

public enum EntryStartSource: String, Codable, Sendable, Equatable {
    case widget
    case control

    public nonisolated var startedBy: StartedBy {
        switch self {
        case .widget: return .widget
        case .control: return .control
        }
    }
}

public enum EntryURLAction: Sendable, Equatable {
    case startReading(source: EntryStartSource)
    case openMarkSheet
    case endReading
    case openBook(bookID: UUID)
}

public enum EntryURLParser: Sendable {
    public nonisolated static func parse(_ url: URL) -> EntryURLAction? {
        guard let scheme = url.scheme?.lowercased(), scheme == "yomuma" else {
            return nil
        }
        guard let host = url.host(percentEncoded: false)?.lowercased() else {
            return nil
        }
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "reading":
            guard pathComponents.count == 1 else { return nil }
            switch pathComponents[0] {
            case "start":
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems,
                      let sourceValue = queryItems.first(where: { $0.name == "source" })?.value,
                      let source = EntryStartSource(rawValue: sourceValue) else {
                    return nil
                }
                return .startReading(source: source)
            case "mark":
                return .openMarkSheet
            case "end":
                return .endReading
            default:
                return nil
            }
        case "book":
            guard pathComponents.count == 1,
                  let uuid = UUID(uuidString: pathComponents[0]) else {
                return nil
            }
            return .openBook(bookID: uuid)
        default:
            return nil
        }
    }

    public nonisolated static func parse(_ urlString: String) -> EntryURLAction? {
        guard let url = URL(string: urlString) else { return nil }
        return parse(url)
    }
}

public enum ValidationError: Error, Sendable, Equatable {
    case empty
    case tooLong(max: Int, actual: Int)
    case notAnInteger
    case containsDecimal
    case outOfRange(min: Int, max: Int, actual: Int)
}

public enum InputValidator: Sendable {
    /// Converts full-width ASCII digits (`０`...`９`) to half-width (`0`...`9`) and trims whitespace.
    public nonisolated static func normalizeDigits(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = String()
        result.reserveCapacity(trimmed.count)
        for scalar in trimmed.unicodeScalars {
            if scalar.value >= 0xFF10 && scalar.value <= 0xFF19,
               let ascii = UnicodeScalar(scalar.value - 0xFF10 + 0x0030) {
                result.unicodeScalars.append(ascii)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// Validates a book title (1...100 grapheme clusters after trimming).
    public nonisolated static func validateTitle(_ raw: String) -> Result<String, ValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = trimmed.count
        if count == 0 {
            return .failure(.empty)
        }
        if count > 100 {
            return .failure(.tooLong(max: 100, actual: count))
        }
        return .success(trimmed)
    }

    /// Validates an author name (0...100 grapheme clusters after trimming).
    public nonisolated static func validateAuthor(_ raw: String) -> Result<String, ValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = trimmed.count
        if count > 100 {
            return .failure(.tooLong(max: 100, actual: count))
        }
        return .success(trimmed)
    }

    /// Validates a saved one-line text (1...60 grapheme clusters after trimming & newline collapse).
    public nonisolated static func validateLine(_ raw: String) -> Result<String, ValidationError> {
        let collapsed = raw
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let count = collapsed.count
        if count == 0 {
            return .failure(.empty)
        }
        if count > 60 {
            return .failure(.tooLong(max: 60, actual: count))
        }
        return .success(collapsed)
    }

    /// Parses an integer with full-width digit normalization, decimal rejection, and range check.
    public nonisolated static func parseInteger(_ raw: String, range: ClosedRange<Int>) -> Result<Int, ValidationError> {
        let normalized = normalizeDigits(raw)
        if normalized.isEmpty {
            return .failure(.empty)
        }
        if normalized.contains(".") || normalized.contains("．") || normalized.contains(",") || normalized.contains("，") {
            return .failure(.containsDecimal)
        }
        // Check if optional leading minus sign + digits
        let scalars = Array(normalized.unicodeScalars)
        var isNegative = false
        var startIndex = 0
        if let first = scalars.first {
            if first == "-" || first == "−" || first == "ー" || first == "－" {
                isNegative = true
                startIndex = 1
            } else if first == "+" || first == "＋" {
                startIndex = 1
            }
        }
        guard startIndex < scalars.count else {
            return .failure(.notAnInteger)
        }
        for scalar in scalars[startIndex...] {
            if scalar.value < 0x0030 || scalar.value > 0x0039 {
                return .failure(.notAnInteger)
            }
        }
        let asciiDigitString = String(String.UnicodeScalarView(scalars[startIndex...]))
        guard let magnitude = Int(asciiDigitString) else {
            return .failure(.outOfRange(min: range.lowerBound, max: range.upperBound, actual: isNegative ? Int.min : Int.max))
        }
        let value = isNegative ? -magnitude : magnitude
        if !range.contains(value) {
            return .failure(.outOfRange(min: range.lowerBound, max: range.upperBound, actual: value))
        }
        return .success(value)
    }

    public nonisolated static func validatePage(_ raw: String) -> Result<Int, ValidationError> {
        parseInteger(raw, range: 1...9999)
    }

    public nonisolated static func validateLocation(_ raw: String) -> Result<Int, ValidationError> {
        parseInteger(raw, range: 1...999999)
    }

    public nonisolated static func validatePercent(_ raw: String) -> Result<Int, ValidationError> {
        parseInteger(raw, range: 0...100)
    }

    public nonisolated static func validateMinutes(_ raw: String) -> Result<Int, ValidationError> {
        parseInteger(raw, range: 1...1440)
    }

    public nonisolated static func validatePublishedYear(_ raw: String) -> Result<Int, ValidationError> {
        parseInteger(raw, range: 1800...2100)
    }

    public nonisolated static func formatProgressDisplay(
        unit: ProgressUnit,
        page: Int?,
        location: Int?,
        percent: Double?
    ) -> String? {
        switch unit {
        case .page:
            guard let page, (1...9999).contains(page) else { return nil }
            return "p.\(page)"
        case .location:
            guard let location, (1...999999).contains(location) else { return nil }
            return "位置\(location)"
        case .percent:
            guard let percent, (0.0...100.0).contains(percent) else { return nil }
            return "\(Int(percent.rounded()))%"
        }
    }
}
