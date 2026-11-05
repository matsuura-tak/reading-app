import Foundation

public enum AwardsCatalog: Sendable {
    private static let bundledItems: [H25AwardItem] = loadBundledAwards()

    private nonisolated static func loadBundledAwards() -> [H25AwardItem] {
        guard let url = Bundle.module.url(forResource: "awards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([H25AwardItem].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Returns all 76 bundled award items from `Resources/awards.json` (AC-112).
    public nonisolated static func allBundledAwards() -> [H25AwardItem] {
        bundledItems
    }

    /// Returns award items filtered by award name, preserving catalog order.
    public nonisolated static func awards(named awardName: String, in catalog: [H25AwardItem]? = nil) -> [H25AwardItem] {
        let source = catalog ?? bundledItems
        return source
            .filter { $0.award == awardName }
            .sorted { $0.order < $1.order }
    }

    /// Normalizes a book title for award matching (ADR-0004 section 6, AC-18〜21):
    /// - Applies NFKC normalization and ASCII uppercasing.
    /// - Strips bracketed publisher/imprint/edition annotations (e.g. `(文春文庫)`, `[新潮文庫]`, `【新装版】`),
    ///   while keeping volume/part indicators (`(上)`, `(下)`, `(2)`, etc.) so multi-volume or derivative titles do not false-match.
    /// - Strips spaces and punctuation (`!`, `？`, `・`, `、`, `。`, quotes, etc.).
    public nonisolated static func normalizeTitle(_ rawTitle: String) -> String {
        let nfkc = rawTitle.precomposedStringWithCompatibilityMapping.uppercased()
        let withoutEditionBrackets = stripEditionBrackets(nfkc)

        let ignoredCharacters = CharacterSet(charactersIn: " \t\n\r\u{3000}!！?？・:：;；,，.．、。\"'”’“‘「」『』()（）[]［］【】〔〕〈〉《》〜～")
        let scalars = withoutEditionBrackets.unicodeScalars.filter { !ignoredCharacters.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    /// Normalizes an author name for award matching using `AuthorNameFormatter` + NFKC.
    public nonisolated static func normalizeAuthor(_ rawAuthor: String?) -> String {
        let formatted = AuthorNameFormatter.format(rawAuthor)
        guard !formatted.isEmpty else { return "" }
        let nfkc = formatted.precomposedStringWithCompatibilityMapping.uppercased()
        let ignored = CharacterSet(charactersIn: " \t\n\r\u{3000}・,，.．")
        let scalars = nfkc.unicodeScalars.filter { !ignored.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    /// Finds all matching award entries where BOTH normalized title and normalized author match (AC-17〜21).
    public nonisolated static func matchAwards(
        title: String,
        author: String?,
        catalog: [H25AwardItem]? = nil
    ) -> [H25AwardItem] {
        let normTitle = normalizeTitle(title)
        let normAuthor = normalizeAuthor(author)
        guard !normTitle.isEmpty, !normAuthor.isEmpty else {
            return []
        }
        let source = catalog ?? bundledItems
        return source.filter { item in
            normalizeTitle(item.title) == normTitle &&
            normalizeAuthor(item.author) == normAuthor
        }
    }

    /// Returns the matched award name (e.g. `"芥川龍之介賞"`) if both title and author match, or `nil`.
    public nonisolated static func matchAwardName(
        title: String,
        author: String?,
        catalog: [H25AwardItem]? = nil
    ) -> String? {
        matchAwards(title: title, author: author, catalog: catalog).first?.award
    }

    private nonisolated static func stripEditionBrackets(_ input: String) -> String {
        let editionKeywords = [
            "文庫", "新書", "単行本", "ブックス", "ノベルス", "ノベルズ",
            "選書", "全集", "叢書", "双書", "出版", "書店", "新装版", "改装版", "改版", "特装版", "愛蔵版"
        ]
        let bracketPairs: [(Character, Character)] = [
            ("(", ")"),
            ("（", "）"),
            ("[", "]"),
            ("［", "］"),
            ("【", "】"),
            ("〔", "〕")
        ]

        var current = input
        for (open, close) in bracketPairs {
            var result = String()
            var index = current.startIndex
            while index < current.endIndex {
                let ch = current[index]
                if ch == open, let closeIdx = current[index...].firstIndex(of: close) {
                    let innerStart = current.index(after: index)
                    let inner = String(current[innerStart..<closeIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let isEdition = editionKeywords.contains { inner.contains($0) }
                    if !isEdition {
                        result.append(inner)
                    }
                    index = current.index(after: closeIdx)
                } else {
                    result.append(ch)
                    index = current.index(after: index)
                }
            }
            current = result
        }
        return current
    }
}
