import Foundation

public struct OCRPageColumnItem: Codable, Sendable, Equatable, Identifiable {
    public var index: Int
    public var id: String { "mark.ocr.column.\(index)" }
    public var text: String
    public var normalizedX: Double
    public var normalizedY: Double

    public nonisolated init(
        index: Int,
        text: String,
        normalizedX: Double,
        normalizedY: Double = 0.5
    ) {
        self.index = index
        self.text = text
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
    }
}

public struct OCRPageResult: Codable, Sendable, Equatable {
    public var mode: H23OCRStubMode
    public var columns: [OCRPageColumnItem]
    public var initialSelectedIndices: [Int]
    public var initialLineText: String
    public var detectedPageNumber: Int?

    public nonisolated init(
        mode: H23OCRStubMode,
        columns: [OCRPageColumnItem],
        initialSelectedIndices: [Int],
        initialLineText: String,
        detectedPageNumber: Int?
    ) {
        self.mode = mode
        self.columns = columns
        self.initialSelectedIndices = initialSelectedIndices
        self.initialLineText = initialLineText
        self.detectedPageNumber = detectedPageNumber
    }
}

public struct ColophonExtractionResult: Codable, Sendable, Equatable {
    public var title: String?
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var publishedYear: Int?
    public var isbn13: String?

    public nonisolated init(
        title: String? = nil,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        isbn13: String? = nil
    ) {
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.publishedYear = publishedYear
        self.isbn13 = isbn13
    }
}

public struct CoverSelectionResult: Codable, Sendable, Equatable {
    public var title: String
    public var author: String?

    public nonisolated init(title: String, author: String? = nil) {
        self.title = title
        self.author = author
    }
}

public struct BookshelfSpineCandidate: Codable, Sendable, Equatable, Identifiable {
    public var index: Int
    public var id: String
    public var title: String
    public var author: String?
    public var publisher: String?
    public var label: String?
    public var isbn13: String?
    public var ndc: String?
    public var publishedYear: Int?
    public var isSelected: Bool
    public var catalogMatchCount: Int

    public nonisolated init(
        index: Int,
        id: String,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        label: String? = nil,
        isbn13: String? = nil,
        ndc: String? = nil,
        publishedYear: Int? = nil,
        isSelected: Bool = true,
        catalogMatchCount: Int = 0
    ) {
        self.index = index
        self.id = id
        self.title = title
        self.author = author
        self.publisher = publisher
        self.label = label
        self.isbn13 = isbn13
        self.ndc = ndc
        self.publishedYear = publishedYear
        self.isSelected = isSelected
        self.catalogMatchCount = catalogMatchCount
    }
}

public enum OCRPipeline: Sendable {
    public static let maxLineCharacters: Int = 60

    // MARK: - 1. Page OCR (AC-65〜68)

    /// Processes recognized OCR columns from a book page:
    /// - Separates page numbers from body columns (AC-67)
    /// - Orders vertical columns right-to-left (`normalizedX` descending) as 1..N (AC-65)
    /// - Selects the leftmost column (`N`) by default (AC-65)
    public nonisolated static func processPageOCR(
        rawColumns: [H23OCRColumn],
        explicitPageNumber: Int? = nil,
        mode: H23OCRStubMode = .pageVertical
    ) -> OCRPageResult {
        var detectedPage: Int? = nil
        if let explicit = explicitPageNumber, (1...9999).contains(explicit) {
            detectedPage = explicit
        }

        var bodyColumns: [H23OCRColumn] = []
        for col in rawColumns {
            let trimmed = col.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if isPageNumberColumn(col, trimmedText: trimmed) {
                if detectedPage == nil,
                   case .success(let pageVal) = InputValidator.validatePage(trimmed) {
                    detectedPage = pageVal
                }
                continue
            }
            bodyColumns.append(col)
        }

        let sorted: [H23OCRColumn]
        if mode == .pageHorizontal {
            sorted = bodyColumns.sorted { lhs, rhs in
                let ly = lhs.normalizedY ?? 0.5
                let ry = rhs.normalizedY ?? 0.5
                if abs(ly - ry) > 0.02 {
                    return ly > ry
                }
                return lhs.normalizedX < rhs.normalizedX
            }
        } else {
            // Vertical Japanese layout: right-to-left (normalizedX descending)
            sorted = bodyColumns.sorted { lhs, rhs in
                if abs(lhs.normalizedX - rhs.normalizedX) > 0.001 {
                    return lhs.normalizedX > rhs.normalizedX
                }
                return (lhs.normalizedY ?? 0.5) > (rhs.normalizedY ?? 0.5)
            }
        }

        let indexedColumns: [OCRPageColumnItem] = sorted.enumerated().map { (offset, item) in
            OCRPageColumnItem(
                index: offset + 1,
                text: VerticalLineLayout.normalizeSingleLine(item.text),
                normalizedX: item.normalizedX,
                normalizedY: item.normalizedY ?? 0.5
            )
        }

        // Default selection: leftmost column (index N) for vertical, or first line (index 1) for horizontal
        let initialIndices: [Int]
        if let last = indexedColumns.last {
            initialIndices = mode == .pageHorizontal ? [1] : [last.index]
        } else {
            initialIndices = []
        }

        let initialText = combineSelectedColumns(columns: indexedColumns, selectedIndices: initialIndices)

        return OCRPageResult(
            mode: mode,
            columns: indexedColumns,
            initialSelectedIndices: initialIndices,
            initialLineText: initialText,
            detectedPageNumber: detectedPage
        )
    }

    /// Combines selected column indices in reading order (`1...N` ascending) and clamps to 60 characters (AC-66).
    public nonisolated static func combineSelectedColumns(
        columns: [OCRPageColumnItem],
        selectedIndices: [Int]
    ) -> String {
        let indexSet = Set(selectedIndices)
        let orderedTexts = columns
            .filter { indexSet.contains($0.index) }
            .sorted { $0.index < $1.index }
            .map(\.text)
        let joined = VerticalLineLayout.normalizeSingleLine(orderedTexts.joined())
        let chars = Array(joined)
        if chars.count > maxLineCharacters {
            return String(chars.prefix(maxLineCharacters))
        }
        return joined
    }

    private nonisolated static func isPageNumberColumn(_ col: H23OCRColumn, trimmedText: String) -> Bool {
        if let explicitFlag = col.isPageNumber {
            return explicitFlag
        }
        // Check if text is purely an integer in 1...9999 and positioned at top/bottom margin or short digits
        let stripped = trimmedText
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "—", with: "")
            .replacingOccurrences(of: " ", with: "")
        if case .success = InputValidator.validatePage(stripped) {
            if let y = col.normalizedY {
                if y <= 0.18 || y >= 0.82 {
                    return true
                }
            }
            if !VerticalLineLayout.containsJapaneseScript(trimmedText) && stripped.count <= 4 {
                return true
            }
        }
        return false
    }

    // MARK: - 2. Colophon OCR (AC-113)

    /// Extracts bibliographic fields (title, author, publisher, label, publishedYear, isbn13) from a colophon (奥付).
    public nonisolated static func parseColophon(_ stub: H23OCRColophon) -> ColophonExtractionResult {
        var result = parseColophonLines(stub.rawLines)
        if let t = stub.extractedTitle, !t.isEmpty { result.title = t }
        if let a = stub.extractedAuthor, !a.isEmpty { result.author = AuthorNameFormatter.format(a) }
        if let p = stub.extractedPublisher, !p.isEmpty { result.publisher = p }
        if let l = stub.extractedLabel, !l.isEmpty { result.label = l }
        if let y = stub.extractedPublishedYear, (1800...2100).contains(y) { result.publishedYear = y }
        if let isbn = stub.extractedISBN13,
           case .success(let validISBN) = ISBNAndCCodeParser.validateISBN13(isbn) {
            result.isbn13 = validISBN
        }
        return result
    }

    public nonisolated static func parseColophonLines(_ lines: [String]) -> ColophonExtractionResult {
        var title: String? = nil
        var author: String? = nil
        var publisher: String? = nil
        var label: String? = nil
        var publishedYear: Int? = nil
        var isbn13: String? = nil

        let prefixTable = ISBNAndCCodeParser.loadedPrefixTable()
        let knownPublishers = prefixTable.prefixes.map(\.publisher)
        let knownLabels = prefixTable.prefixes.compactMap(\.bunkoLabel) + prefixTable.prefixes.compactMap(\.shinshoLabel)

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            // 1. Check ISBN
            if isbn13 == nil, let extractedISBN = extractISBN13FromLine(line) {
                isbn13 = extractedISBN
            }

            // 2. Check published year (4 digits followed by 年)
            if publishedYear == nil, let year = extractYearFromLine(line) {
                publishedYear = year
            }

            // 3. Check labeled author line
            if author == nil, let extractedAuthor = extractPrefixedValue(
                from: line,
                prefixes: ["著者", "著　者", "作者", "作　者", "著"]
            ) {
                let formatted = AuthorNameFormatter.format(extractedAuthor)
                if !formatted.isEmpty {
                    author = formatted
                }
            }

            // 4. Check labeled publisher line
            if publisher == nil, let extractedPub = extractPrefixedValue(
                from: line,
                prefixes: ["発行所", "発　行　所", "発行元", "出版社", "発行"]
            ) {
                let cleanedPub = extractedPub
                    .replacingOccurrences(of: "株式会社", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedPub.isEmpty {
                    publisher = cleanedPub
                }
            }

            // 5. Check labeled imprint/label line
            if label == nil, let extractedLabel = extractPrefixedValue(
                from: line,
                prefixes: ["レーベル", "叢書", "シリーズ"]
            ) {
                if !extractedLabel.isEmpty {
                    label = extractedLabel
                }
            }

            // 6. Check known labels /文庫/新書 in line
            if label == nil {
                for kl in knownLabels where line.contains(kl) {
                    label = kl
                    break
                }
            }

            // 7. Check known publishers in line
            if publisher == nil {
                for kp in knownPublishers where line.contains(kp) {
                    publisher = kp
                    break
                }
            }
        }

        // If ISBN was found and publisher is still nil, derive from ISBN prefix
        if let isbn = isbn13, publisher == nil {
            publisher = ISBNAndCCodeParser.lookupPublisherEntry(isbn13: isbn)?.publisher
        }

        // First non-metadata line can serve as fallback title
        if let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !first.isEmpty,
           !first.hasPrefix("著者"),
           !first.hasPrefix("発行"),
           !first.uppercased().contains("ISBN") {
            title = first
        }

        return ColophonExtractionResult(
            title: title,
            author: author,
            publisher: publisher,
            label: label,
            publishedYear: publishedYear,
            isbn13: isbn13
        )
    }

    private nonisolated static func extractPrefixedValue(from line: String, prefixes: [String]) -> String? {
        for prefix in prefixes {
            if line.hasPrefix(prefix) {
                let remainder = String(line.dropFirst(prefix.count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: " 　:：・\t"))
                if !remainder.isEmpty {
                    return remainder
                }
            }
        }
        return nil
    }

    private nonisolated static func extractISBN13FromLine(_ line: String) -> String? {
        let normalized = InputValidator.normalizeDigits(line)
        // Extract all digit runs (allowing hyphens between digits)
        var buffer = String()
        for ch in normalized {
            if ch.isASCII && ch.isNumber {
                buffer.append(ch)
            } else if ch == "-" || ch == "－" || ch == "‐" || ch == " " {
                continue
            } else {
                if buffer.count >= 13, let found = findValidISBN13Substring(in: buffer) {
                    return found
                }
                buffer.removeAll()
            }
        }
        if buffer.count >= 13, let found = findValidISBN13Substring(in: buffer) {
            return found
        }
        return nil
    }

    private nonisolated static func findValidISBN13Substring(in digits: String) -> String? {
        let chars = Array(digits)
        guard chars.count >= 13 else { return nil }
        for start in 0...(chars.count - 13) {
            let sub = String(chars[start..<(start + 13)])
            if (sub.hasPrefix("978") || sub.hasPrefix("979")),
               case .success(let valid) = ISBNAndCCodeParser.validateISBN13(sub) {
                return valid
            }
        }
        return nil
    }

    private nonisolated static func extractYearFromLine(_ line: String) -> Int? {
        let normalized = InputValidator.normalizeDigits(line)
        let chars = Array(normalized)
        guard chars.count >= 5 else { return nil }
        for i in 0...(chars.count - 5) {
            if chars[i + 4] == "年" {
                let sub = String(chars[i..<(i + 4)])
                if let year = Int(sub), (1800...2100).contains(year) {
                    return year
                }
            }
        }
        return nil
    }

    // MARK: - 3. Cover 2-Tap Selection (AC-137)

    /// Resolves a 2-tap cover OCR selection where the 1st tap selects the title line and the optional 2nd tap selects the author line.
    public nonisolated static func resolveCoverSelection(
        coverLines: [String],
        titleLineIndex: Int,
        authorLineIndex: Int? = nil
    ) -> CoverSelectionResult? {
        guard coverLines.indices.contains(titleLineIndex) else {
            return nil
        }
        let rawTitle = coverLines[titleLineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTitle.isEmpty else {
            return nil
        }
        let clampedTitle = String(rawTitle.prefix(100))

        var resolvedAuthor: String? = nil
        if let aIdx = authorLineIndex, coverLines.indices.contains(aIdx), aIdx != titleLineIndex {
            let formatted = AuthorNameFormatter.format(coverLines[aIdx])
            if !formatted.isEmpty {
                resolvedAuthor = String(formatted.prefix(100))
            }
        }
        return CoverSelectionResult(title: clampedTitle, author: resolvedAuthor)
    }

    // MARK: - 4. Bookshelf Multi-Spine OCR (AC-138)

    /// Processes recognized bookshelf spines and auto-completes bibliographic fields ONLY when the catalog has a unique (1-item) match (AC-138).
    public nonisolated static func processBookshelfSpines(
        spines: [H23OCRSpineItem],
        catalog: [H20BiblioItem] = []
    ) -> [BookshelfSpineCandidate] {
        let ordered = spines.enumerated().sorted { lhs, rhs in
            if let lx = lhs.element.normalizedX, let rx = rhs.element.normalizedX, abs(lx - rx) > 0.001 {
                return lx < rx
            }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var results: [BookshelfSpineCandidate] = []
        for (idx, spine) in ordered.enumerated() {
            let trimmedTitle = spine.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }

            let normSpineTitle = AwardsCatalog.normalizeTitle(trimmedTitle)
            let matches = catalog.filter { item in
                let normCatTitle = AwardsCatalog.normalizeTitle(item.title)
                guard !normCatTitle.isEmpty, !normSpineTitle.isEmpty else { return false }
                if normCatTitle == normSpineTitle {
                    if let spineAuthor = spine.author, !spineAuthor.isEmpty {
                        let normSpineAuthor = AwardsCatalog.normalizeAuthor(spineAuthor)
                        let normCatAuthor = AwardsCatalog.normalizeAuthor(item.author ?? item.rawDcCreator)
                        if !normSpineAuthor.isEmpty && !normCatAuthor.isEmpty {
                            return normSpineAuthor == normCatAuthor
                        }
                    }
                    return true
                }
                return false
            }

            let index = idx + 1
            let itemID = spine.id ?? "spine-\(index)"

            if matches.count == 1, let uniqueMatch = matches.first {
                // Exactly 1 catalog match -> auto-complete bibliographic fields (AC-138)
                let author = AuthorNameFormatter.format(uniqueMatch.author ?? uniqueMatch.rawDcCreator ?? spine.author)
                results.append(
                    BookshelfSpineCandidate(
                        index: index,
                        id: itemID,
                        title: uniqueMatch.title,
                        author: author.isEmpty ? nil : author,
                        publisher: uniqueMatch.publisher,
                        label: uniqueMatch.label,
                        isbn13: uniqueMatch.isbn13,
                        ndc: uniqueMatch.ndc,
                        publishedYear: uniqueMatch.publishedYear,
                        isSelected: true,
                        catalogMatchCount: 1
                    )
                )
            } else {
                // 0 or >= 2 matches -> do NOT guess/overwrite from ambiguous catalog entries (AC-138)
                let spineAuthor = AuthorNameFormatter.format(spine.author)
                results.append(
                    BookshelfSpineCandidate(
                        index: index,
                        id: itemID,
                        title: trimmedTitle,
                        author: spineAuthor.isEmpty ? nil : spineAuthor,
                        publisher: nil,
                        label: nil,
                        isbn13: nil,
                        ndc: nil,
                        publishedYear: nil,
                        isSelected: true,
                        catalogMatchCount: matches.count
                    )
                )
            }
        }
        return results
    }
}
