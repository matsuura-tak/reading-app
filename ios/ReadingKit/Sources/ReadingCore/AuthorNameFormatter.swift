import Foundation

public enum AuthorNameFormatter: Sendable {
    /// Formats a raw NDL `dc:creator` or bibliographic author string into a clean single author name (ADR-0004 / AC-92).
    ///
    /// Rules:
    /// 1. Keep only the first author segment before `;`, `；`, `/`, or `／`.
    /// 2. Remove parenthetical/bracketed annotations such as `(小説家)`, `（1949-）`, `[著]`, `［訳］`.
    /// 3. Remove birth-death year tokens such as `1867-1916`, `1979-`, `1900–1980`.
    /// 4. Remove role suffixes (`著`, `作`, `編`, `編著`, `訳`, `監修`, `解説`, `ほか`, `他`).
    /// 5. For Japanese names, remove commas and spaces between family and given names.
    public nonisolated static func format(_ raw: String?) -> String {
        guard let raw else { return "" }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // 1. Split on multi-author separators and keep the first non-empty part
        let multiSeparators = CharacterSet(charactersIn: ";；/／")
        let firstSegment = trimmed
            .components(separatedBy: multiSeparators)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? trimmed
        guard !firstSegment.isEmpty else { return "" }

        // 2. Strip bracketed segments: (...), （...）, [...], ［...］, 【...】
        var cleaned = stripBracketedSegments(firstSegment)

        // 3. Remove birth-death year patterns (e.g. ", 1979-", "1867-1916", "1949 - ")
        cleaned = stripYearRanges(cleaned)

        // 4. Remove trailing role tokens preceded by whitespace/comma, plus unambiguous trailing role words
        cleaned = stripRoleSuffixes(cleaned)

        // 5. Clean up commas and spaces
        if VerticalLineLayout.containsJapaneseScript(cleaned) {
            let removeSet = CharacterSet(charactersIn: ",，、 \t\u{3000}")
            let compact = cleaned.unicodeScalars.filter { !removeSet.contains($0) }
            return String(String.UnicodeScalarView(compact))
        } else {
            // For Western names, replace commas with spaces and collapse multiple spaces
            let noCommas = cleaned
                .replacingOccurrences(of: ",", with: " ")
                .replacingOccurrences(of: "，", with: " ")
            let parts = noCommas
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            return parts.joined(separator: " ")
        }
    }

    private nonisolated static func stripBracketedSegments(_ input: String) -> String {
        let pairs: [(Character, Character)] = [
            ("(", ")"),
            ("（", "）"),
            ("[", "]"),
            ("［", "］"),
            ("【", "】")
        ]
        var current = input
        for (open, close) in pairs {
            var out = String()
            var depth = 0
            for ch in current {
                if ch == open {
                    depth += 1
                } else if ch == close {
                    if depth > 0 {
                        depth -= 1
                    } else {
                        out.append(ch)
                    }
                } else if depth == 0 {
                    out.append(ch)
                }
            }
            current = out
        }
        return current
    }

    private nonisolated static func stripYearRanges(_ input: String) -> String {
        // Split by commas/spaces and drop tokens that look like year ranges (e.g., "1979-", "1867-1916", "1980~")
        let normalizedDashes = input
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "―", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "〜", with: "-")
            .replacingOccurrences(of: "～", with: "-")

        var result = normalizedDashes
        // Match 3-4 digits followed by '-' and optional 1-4 digits, or '-' followed by 3-4 digits
        let tokens = result.components(separatedBy: CharacterSet(charactersIn: ",，、 \t\u{3000}"))
        let filtered = tokens.filter { token in
            let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return false }
            if isYearToken(t) { return false }
            return true
        }
        result = filtered.joined(separator: " ")
        return result
    }

    private nonisolated static func isYearToken(_ token: String) -> Bool {
        let chars = Array(token)
        guard chars.contains("-") else { return false }
        let parts = token.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let left = parts[0]
        let right = parts[1]
        let leftIsYear = (3...4).contains(left.count) && left.allSatisfy { $0.isNumber }
        let rightIsEmptyOrYear = right.isEmpty || ((1...4).contains(right.count) && right.allSatisfy { $0.isNumber })
        if leftIsYear && rightIsEmptyOrYear {
            return true
        }
        let leftIsEmpty = left.isEmpty
        let rightIsFullYear = (3...4).contains(right.count) && right.allSatisfy { $0.isNumber }
        return leftIsEmpty && rightIsFullYear
    }

    private nonisolated static func stripRoleSuffixes(_ input: String) -> String {
        let roleTokens: Set<String> = [
            "著", "作", "編", "編著", "訳", "監修", "解説", "ほか", "他", "共著", "共編", "共訳", "原著", "原作"
        ]
        var parts = input
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        while let last = parts.last, roleTokens.contains(last) {
            parts.removeLast()
        }

        var joined = parts.joined(separator: " ")
        let unambiguousSuffixes = ["編著", "監修", "解説", "共著", "共編", "共訳", "原著", "原作", "ほか", "著"]
        var changed = true
        while changed {
            changed = false
            for suffix in unambiguousSuffixes {
                if joined.hasSuffix(suffix) && joined.count > suffix.count {
                    joined = String(joined.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    changed = true
                }
            }
        }
        return joined
    }
}
