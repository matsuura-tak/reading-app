import Foundation

public enum BarcodeParseError: Error, Sendable, Equatable {
    case empty
    case nonBookBarcode(String)
    case invalidLength(Int)
    case nonDigits
    case invalidCheckDigit
}

public struct CCodeInfo: Codable, Sendable, Equatable {
    public var rawCode: String
    public var cCode4: String
    public var targetDigit: String
    public var formatDigit: String
    public var contentCode: String
    public var formatLabel: String?

    public nonisolated init(
        rawCode: String,
        cCode4: String,
        targetDigit: String,
        formatDigit: String,
        contentCode: String,
        formatLabel: String?
    ) {
        self.rawCode = rawCode
        self.cCode4 = cCode4
        self.targetDigit = targetDigit
        self.formatDigit = formatDigit
        self.contentCode = contentCode
        self.formatLabel = formatLabel
    }
}

public struct PublisherPrefixEntry: Codable, Sendable, Equatable {
    public var prefix: String
    public var publisher: String
    public var bunkoLabel: String?
    public var shinshoLabel: String?

    public nonisolated init(
        prefix: String,
        publisher: String,
        bunkoLabel: String? = nil,
        shinshoLabel: String? = nil
    ) {
        self.prefix = prefix
        self.publisher = publisher
        self.bunkoLabel = bunkoLabel
        self.shinshoLabel = shinshoLabel
    }
}

public struct PublisherPrefixTable: Codable, Sendable, Equatable {
    public var prefixes: [PublisherPrefixEntry]
    public var formats: [String: String]

    public nonisolated init(prefixes: [PublisherPrefixEntry], formats: [String: String]) {
        self.prefixes = prefixes
        self.formats = formats
    }
}

public struct BarcodeMetadataResult: Sendable, Equatable {
    public var isbn13: String
    public var publisher: String?
    /// Format label directly from C-code 5th digit (e.g. "文庫", "新書", "単行本").
    public var formatLabel: String?
    /// Publisher-specific imprint label derived from publisher + C-code (e.g. "新潮文庫", "岩波文庫").
    public var imprintLabel: String?
    public var cCode: CCodeInfo?

    public nonisolated init(
        isbn13: String,
        publisher: String? = nil,
        formatLabel: String? = nil,
        imprintLabel: String? = nil,
        cCode: CCodeInfo? = nil
    ) {
        self.isbn13 = isbn13
        self.publisher = publisher
        self.formatLabel = formatLabel
        self.imprintLabel = imprintLabel
        self.cCode = cCode
    }
}

public enum ISBNAndCCodeParser: Sendable {
    public static let nonBookGuidanceMessage = "本のバーコード（978または979で始まるもの）を映してください"

    private static let bundledTable: PublisherPrefixTable = loadBundledTable()

    private nonisolated static func loadBundledTable() -> PublisherPrefixTable {
        guard let url = Bundle.module.url(forResource: "publisher-prefixes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(PublisherPrefixTable.self, from: data) else {
            return PublisherPrefixTable(prefixes: [], formats: [:])
        }
        return decoded
    }

    public nonisolated static func loadedPrefixTable() -> PublisherPrefixTable {
        bundledTable
    }

    /// Cleans hyphens/spaces and normalizes full-width digits to ASCII digits.
    public nonisolated static func cleanDigits(_ raw: String) -> String {
        let normalized = InputValidator.normalizeDigits(raw)
        let stripped = normalized
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "－", with: "")
            .replacingOccurrences(of: "‐", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
        return stripped
    }

    /// Validates an ISBN-13 string (must start with 978 or 979 and pass Modulo-10 check digit).
    public nonisolated static func validateISBN13(_ raw: String) -> Result<String, BarcodeParseError> {
        let cleaned = cleanDigits(raw)
        guard !cleaned.isEmpty else {
            return .failure(.empty)
        }
        guard cleaned.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return .failure(.nonDigits)
        }
        if cleaned.count == 13 && !(cleaned.hasPrefix("978") || cleaned.hasPrefix("979")) {
            return .failure(.nonBookBarcode(cleaned))
        }
        guard cleaned.count == 13 else {
            if cleaned.hasPrefix("49") || cleaned.hasPrefix("45") || cleaned.hasPrefix("192") || cleaned.hasPrefix("191") {
                return .failure(.nonBookBarcode(cleaned))
            }
            return .failure(.invalidLength(cleaned.count))
        }
        guard verifyEAN13CheckDigit(cleaned) else {
            return .failure(.invalidCheckDigit)
        }
        return .success(cleaned)
    }

    /// Verifies the EAN-13 Modulo-10 (weights 1 and 3) check digit.
    public nonisolated static func verifyEAN13CheckDigit(_ digits13: String) -> Bool {
        let chars = Array(digits13)
        guard chars.count == 13 else { return false }
        var sum = 0
        for (index, ch) in chars.enumerated() {
            guard let digit = ch.wholeNumberValue else { return false }
            sum += digit * (index.isMultiple(of: 2) ? 1 : 3)
        }
        return sum.isMultiple(of: 10)
    }

    /// Computes the 13th check digit for a 12-digit EAN/ISBN prefix.
    public nonisolated static func computeEAN13CheckDigit(_ prefix12: String) -> Character? {
        let chars = Array(prefix12)
        guard chars.count == 12 else { return nil }
        var sum = 0
        for (index, ch) in chars.enumerated() {
            guard let digit = ch.wholeNumberValue else { return nil }
            sum += digit * (index.isMultiple(of: 2) ? 1 : 3)
        }
        let check = (10 - (sum % 10)) % 10
        return Character(String(check))
    }

    /// Parses a 2nd-tier Japanese book barcode (`192...` or `191...`, 13 digits) or a 4-digit C-code (`C0193` / `0193`).
    public nonisolated static func parseCCode(_ raw: String) -> CCodeInfo? {
        let cleaned = cleanDigits(raw.uppercased().replacingOccurrences(of: "C", with: ""))
        let chars = Array(cleaned)
        if chars.count == 13, cleaned.hasPrefix("192") || cleaned.hasPrefix("191") {
            let cCode4 = String(chars[3...6])
            let targetDigit = String(chars[3])
            let formatDigit = String(chars[4])
            let contentCode = String(chars[5...6])
            let formatLabel = bundledTable.formats[formatDigit]
            return CCodeInfo(
                rawCode: cleaned,
                cCode4: cCode4,
                targetDigit: targetDigit,
                formatDigit: formatDigit,
                contentCode: contentCode,
                formatLabel: formatLabel
            )
        } else if chars.count == 4, chars.allSatisfy({ $0.isASCII && $0.isNumber }) {
            let cCode4 = cleaned
            let targetDigit = String(chars[0])
            let formatDigit = String(chars[1])
            let contentCode = String(chars[2...3])
            let formatLabel = bundledTable.formats[formatDigit]
            return CCodeInfo(
                rawCode: cleaned,
                cCode4: cCode4,
                targetDigit: targetDigit,
                formatDigit: formatDigit,
                contentCode: contentCode,
                formatLabel: formatLabel
            )
        }
        return nil
    }

    /// Looks up the Japanese publisher entry from an ISBN-13 (`9784...`).
    public nonisolated static func lookupPublisherEntry(isbn13: String) -> PublisherPrefixEntry? {
        let cleaned = cleanDigits(isbn13)
        guard cleaned.count == 13, cleaned.hasPrefix("9784") else {
            return nil
        }
        let registrantAndItem = String(cleaned.dropFirst(4).dropLast(1))
        // Sort matching prefixes by length descending (longest prefix match wins)
        let matches = bundledTable.prefixes.filter { registrantAndItem.hasPrefix($0.prefix) }
        return matches.max(by: { $0.prefix.count < $1.prefix.count })
    }

    /// Combines ISBN-13 and optional 2nd-tier `192` barcode to derive offline publisher and label (AC-3, AC-11).
    public nonisolated static func resolveMetadata(
        isbn13: String,
        supplementalCode: String? = nil
    ) -> Result<BarcodeMetadataResult, BarcodeParseError> {
        switch validateISBN13(isbn13) {
        case .failure(let error):
            return .failure(error)
        case .success(let validISBN):
            let entry = lookupPublisherEntry(isbn13: validISBN)
            let cCodeInfo = supplementalCode.flatMap { parseCCode($0) }
            let formatLabel = cCodeInfo?.formatLabel
            var imprintLabel: String? = formatLabel
            if let cCodeInfo, let entry {
                switch cCodeInfo.formatDigit {
                case "1":
                    imprintLabel = entry.bunkoLabel ?? formatLabel
                case "2":
                    imprintLabel = entry.shinshoLabel ?? formatLabel
                default:
                    imprintLabel = formatLabel
                }
            }
            return .success(
                BarcodeMetadataResult(
                    isbn13: validISBN,
                    publisher: entry?.publisher,
                    formatLabel: formatLabel,
                    imprintLabel: imprintLabel,
                    cCode: cCodeInfo
                )
            )
        }
    }
}
