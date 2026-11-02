import Foundation

public struct VerticalShortenResult: Sendable, Equatable {
    public var text: String
    public var shortened: Bool

    public nonisolated init(text: String, shortened: Bool) {
        self.text = text
        self.shortened = shortened
    }
}

public enum VerticalLineLayout: Sendable {
    public static let maxWidgetCharacters: Int = 25
    public static let defaultCardMaxColumns: Int = 6
    public static let defaultCardRowsPerColumn: Int = 13

    private static let verticalPresentationMap: [Character: String] = [
        "、": "\u{FE11}", // ︑
        "。": "\u{FE12}", // ︒
        "「": "\u{FE41}", // ﹁
        "」": "\u{FE42}", // ﹂
        "『": "\u{FE43}", // ﹃
        "』": "\u{FE44}", // ﹄
        "（": "\u{FE35}", // ︵
        "(": "\u{FE35}",  // ︵
        "）": "\u{FE36}", // ︶
        ")": "\u{FE36}",  // ︶
        "〔": "\u{FE39}", // ︹
        "〕": "\u{FE3A}", // ︺
        "【": "\u{FE3B}", // ︻
        "】": "\u{FE3C}", // ︼
        "〈": "\u{FE3F}", // ︿
        "〉": "\u{FE40}", // ﹀
        "《": "\u{FE3D}", // ︽
        "》": "\u{FE3E}", // ︾
        "［": "\u{FE47}", // ﹇
        "[": "\u{FE47}",  // ﹇
        "］": "\u{FE48}", // ﹈
        "]": "\u{FE48}",  // ﹈
        "｛": "\u{FE37}", // ︷
        "{": "\u{FE37}",  // ︷
        "｝": "\u{FE38}", // ︸
        "}": "\u{FE38}",  // ︸
        "…": "\u{FE19}", // ︙
        "‥": "\u{FE30}"  // ︰
    ]

    private static let rotated90Map: [Character: String] = [
        "ー": "ー",
        "―": "―",
        "—": "—",
        "–": "–",
        "-": "－",
        "‐": "‐",
        "〜": "〜",
        "～": "～",
        "゠": "゠",
        "：": "：",
        ":": "：",
        "；": "；",
        ";": "；",
        "－": "－",
        "＝": "＝",
        "=": "＝",
        "＜": "＜",
        "<": "＜",
        "＞": "＞",
        ">": "＞",
        "｜": "｜",
        "|": "｜",
        "＿": "＿",
        "_": "＿"
    ]

    private static let smallOffsetCharacters: Set<Character> = [
        "ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ", "ゎ", "ゕ", "ゖ",
        "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ", "ヵ", "ヶ",
        "，", "．"
    ]

    public static let prohibitedLineStartCharacters: Set<Character> = [
        "、", "。", "，", "．", "・", "：", "；", "！", "？", "!", "?",
        "」", "』", "）", ")", "〕", "】", "〉", "》", "］", "]", "｝", "}",
        "ー", "〜", "～", "…", "‥", "ゝ", "ゞ", "ヽ", "ヾ", "々",
        "ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "っ", "ゃ", "ゅ", "ょ", "ゎ", "ゕ", "ゖ",
        "ァ", "ィ", "ゥ", "ェ", "ォ", "ッ", "ャ", "ュ", "ョ", "ヮ", "ヵ", "ヶ",
        "\u{FE11}", "\u{FE12}", "\u{FE42}", "\u{FE44}", "\u{FE36}",
        "\u{FE3A}", "\u{FE3C}", "\u{FE40}", "\u{FE3E}", "\u{FE48}", "\u{FE38}",
        "\u{FE19}", "\u{FE30}"
    ]

    /// Normalizes newlines and leading/trailing spaces for single-line display.
    public nonisolated static func normalizeSingleLine(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Shortens a line to at most 25 characters according to ADR-0003 / AC-29:
    /// - <= 25 chars: unchanged (`shortened = false`)
    /// - >= 26 chars: if a `、` or `。` exists at 1-based positions 13...25 (indices 12...24),
    ///   cut right after the last such punctuation in that range (including the punctuation, no `…`).
    ///   Otherwise cut at 24 characters + `…` (total 25 characters).
    public nonisolated static func shortenForWidget(_ raw: String) -> VerticalShortenResult {
        let normalized = normalizeSingleLine(raw)
        let chars = Array(normalized)
        guard chars.count > maxWidgetCharacters else {
            return VerticalShortenResult(text: normalized, shortened: false)
        }
        // Inspect 1-based positions 13...25 -> 0-based indices 12...24
        for idx in stride(from: 24, through: 12, by: -1) {
            let ch = chars[idx]
            if ch == "、" || ch == "。" {
                let prefix = String(chars[0...idx])
                return VerticalShortenResult(text: prefix, shortened: true)
            }
        }
        let prefix24 = String(chars[0..<24]) + "…"
        return VerticalShortenResult(text: prefix24, shortened: true)
    }

    /// Returns true if the string contains at least one Hiragana, Katakana, or Han character (AC-30).
    public nonisolated static func containsJapaneseScript(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x3040...0x309F).contains(v) || // Hiragana
               (0x30A0...0x30FF).contains(v) || // Katakana
               (0x31F0...0x31FF).contains(v) || // Katakana Phonetic Extensions
               (0xFF66...0xFF9F).contains(v) || // Halfwidth Katakana
               (0x3005...0x3007).contains(v) || // 々, 〆, 〇
               (0x3400...0x4DBF).contains(v) || // CJK Extension A
               (0x4E00...0x9FFF).contains(v) || // CJK Unified Ideographs
               (0xF900...0xFAFF).contains(v) || // CJK Compatibility Ideographs
               (0x20000...0x2FA1F).contains(v) || // CJK Extensions B..F
               scalar.properties.isIdeographic {
                return true
            }
        }
        return false
    }

    /// Transforms a single source character into its vertical display string, rotation (0 or 90), and offset (dx, dy).
    public nonisolated static func transformCharacter(_ ch: Character) -> (display: String, rotation: Int, dx: Double, dy: Double) {
        if let mapped = verticalPresentationMap[ch] {
            return (display: mapped, rotation: 0, dx: 0.0, dy: 0.0)
        }
        if let rotated = rotated90Map[ch] {
            return (display: rotated, rotation: 90, dx: 0.0, dy: 0.0)
        }
        if smallOffsetCharacters.contains(ch) {
            return (display: String(ch), rotation: 0, dx: 0.12, dy: -0.10)
        }
        // Convert remaining half-width ASCII to full-width for vertical alignment
        if ch.unicodeScalars.count == 1, let scalar = ch.unicodeScalars.first {
            if scalar.value == 0x0020 {
                return (display: "\u{3000}", rotation: 0, dx: 0.0, dy: 0.0)
            }
            if scalar.value >= 0x0021 && scalar.value <= 0x007E,
               let fullWidth = UnicodeScalar(scalar.value - 0x0021 + 0xFF01) {
                return (display: String(fullWidth), rotation: 0, dx: 0.0, dy: 0.0)
            }
        }
        return (display: String(ch), rotation: 0, dx: 0.0, dy: 0.0)
    }

    /// Replaces vertical presentation forms (U+FE10...U+FE4F) back with standard horizontal punctuation for VoiceOver (AC-99).
    public nonisolated static func stripVerticalPresentationForms(_ text: String) -> String {
        let reverseMap: [UnicodeScalar: Character] = [
            "\u{FE11}": "、",
            "\u{FE12}": "。",
            "\u{FE41}": "「",
            "\u{FE42}": "」",
            "\u{FE43}": "『",
            "\u{FE44}": "』",
            "\u{FE35}": "（",
            "\u{FE36}": "）",
            "\u{FE39}": "〔",
            "\u{FE3A}": "〕",
            "\u{FE3B}": "【",
            "\u{FE3C}": "】",
            "\u{FE3F}": "〈",
            "\u{FE40}": "〉",
            "\u{FE3D}": "《",
            "\u{FE3E}": "》",
            "\u{FE47}": "［",
            "\u{FE48}": "］",
            "\u{FE37}": "｛",
            "\u{FE38}": "｝",
            "\u{FE19}": "…",
            "\u{FE30}": "‥"
        ]
        var out = String()
        out.reserveCapacity(text.count)
        for scalar in text.unicodeScalars {
            if let replacement = reverseMap[scalar] {
                out.append(replacement)
            } else if (0xFE10...0xFE4F).contains(scalar.value) {
                // Skip any other vertical presentation form so VoiceOver never stumbles
                continue
            } else {
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    /// Splits characters into vertical columns (1-based right-to-left) while enforcing line-start Kinsoku.
    /// アプリの中の縦書きの帯（BannerNoticeView）用。W-1・W-2 の組み方は `WidgetLineComposer`（枠から決め直す）。
    public nonisolated static func layoutVerticalCells(
        text: String,
        maxColumns: Int,
        rowsPerColumn: Int
    ) -> [H22GlyphCell] {
        let chars = Array(text)
        guard !chars.isEmpty, maxColumns > 0, rowsPerColumn > 0 else {
            return []
        }

        var columns: [[Character]] = []
        var index = 0
        while index < chars.count && columns.count < maxColumns {
            let remaining = chars.count - index
            let takeCount = min(rowsPerColumn, remaining)
            var currentColumn = Array(chars[index..<(index + takeCount)])
            index += takeCount

            // If there are still characters left for the next column and the next character is prohibited at column start,
            // perform oidashi (push trailing characters of currentColumn into the next column until the next column starts
            // with a non-prohibited character, keeping at least 1 character in currentColumn).
            if index < chars.count && columns.count + 1 < maxColumns {
                while currentColumn.count > 1 && prohibitedLineStartCharacters.contains(chars[index]) {
                    index -= 1
                    currentColumn.removeLast()
                }
            }

            columns.append(currentColumn)
        }

        var cells: [H22GlyphCell] = []
        for (colIdx, colChars) in columns.enumerated() {
            let columnNumber = colIdx + 1
            for (rowIdx, ch) in colChars.enumerated() {
                let rowNumber = rowIdx + 1
                let transformed = transformCharacter(ch)
                cells.append(
                    H22GlyphCell(
                        column: columnNumber,
                        row: rowNumber,
                        source: String(ch),
                        display: transformed.display,
                        rotation: transformed.rotation,
                        dx: transformed.dx,
                        dy: transformed.dy
                    )
                )
            }
        }
        return cells
    }

    /// Builds the single VoiceOver accessibility label for a widget snapshot (AC-99, design/ 6 W-1・W-2, 決まり 53).
    /// 書式は「書名、場所。一行」。著者は入れない。一行は保存した一行（縦書き用の字形を外したもの）から作る。
    public nonisolated static func buildWidgetAccessibilityLabel(
        snapshot: WidgetSnapshot,
        strings: WidgetSpokenStrings = .japanese
    ) -> String {
        guard let book = snapshot.currentBook else {
            return strings.empty
        }
        let title: String
        if snapshot.hideOnWidgets {
            title = strings.hidden
        } else if book.isTitlePending {
            title = strings.currentBookAsTitle
        } else if let bookTitle = book.title?.trimmingCharacters(in: .whitespacesAndNewlines), !bookTitle.isEmpty {
            title = bookTitle
        } else {
            // 書名の所は、title がなければ widget.currentBookAsTitle（契約の「出し方」）。
            title = strings.currentBookAsTitle
        }
        let place = strings.spokenProgress(book.progress)
        var line: String?
        if !snapshot.hideOnWidgets, let raw = book.line {
            // 写しは全文を持つ。読み上げはウィジェットに描く一行（25字に縮めたもの）と同じにする（G3 r2 までと同じ文）。
            let shown = shortenForWidget(raw).text
            let stripped = stripVerticalPresentationForms(shown).trimmingCharacters(in: .whitespacesAndNewlines)
            line = stripped.isEmpty ? nil : stripped
        }
        return strings.spokenLabel(title: title, place: place, line: line)
    }
}
