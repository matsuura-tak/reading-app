import Foundation
import Testing
@testable import ReadingCore

@Suite("VerticalLineLayout Tests")
struct VerticalLineLayoutTests {

    @Test("25-character shortening rule (AC-29) handles all boundary cases")
    func shortenForWidgetBoundaries() {
        // 1. <= 25 chars: unchanged, shortened = false
        let exact25 = String(repeating: "あ", count: 25)
        let res25 = VerticalLineLayout.shortenForWidget(exact25)
        #expect(res25.text == exact25)
        #expect(res25.shortened == false)

        // 2. 31 chars with '、' at 18th char (1-based) -> cut at 18th char including '、', no '…'
        let line18 = String(repeating: "あ", count: 17) + "、" + String(repeating: "い", count: 13)
        let res18 = VerticalLineLayout.shortenForWidget(line18)
        #expect(res18.text == String(repeating: "あ", count: 17) + "、")
        #expect(res18.shortened == true)

        // 3. 31 chars with '、' at 13th char (1-based boundary) -> cut at 13th char including '、'
        let line13 = String(repeating: "あ", count: 12) + "、" + String(repeating: "い", count: 18)
        let res13 = VerticalLineLayout.shortenForWidget(line13)
        #expect(res13.text == String(repeating: "あ", count: 12) + "、")
        #expect(res13.shortened == true)

        // 4. 31 chars with '。' at 25th char (1-based upper boundary) -> cut at 25th char including '。'
        let line25 = String(repeating: "あ", count: 24) + "。" + String(repeating: "い", count: 6)
        let res25Punct = VerticalLineLayout.shortenForWidget(line25)
        #expect(res25Punct.text == String(repeating: "あ", count: 24) + "。")
        #expect(res25Punct.shortened == true)

        // 5. 31 chars with '、' at 12th char (before 13th char) -> fallback to 24 chars + '…'
        let line12 = String(repeating: "あ", count: 11) + "、" + String(repeating: "い", count: 19)
        let res12 = VerticalLineLayout.shortenForWidget(line12)
        #expect(res12.text == String(repeating: "あ", count: 11) + "、" + String(repeating: "い", count: 12) + "…")
        #expect(res12.text.count == 25)
        #expect(res12.shortened == true)

        // 6. 30 chars with no punctuation -> 24 chars + '…'
        let lineNoPunct = String(repeating: "あ", count: 30)
        let resNoPunct = VerticalLineLayout.shortenForWidget(lineNoPunct)
        #expect(resNoPunct.text == String(repeating: "あ", count: 24) + "…")
        #expect(resNoPunct.text.count == 25)
        #expect(resNoPunct.shortened == true)
    }

    @Test("Vertical glyph replacement, 90-degree rotation, and Kinsoku (AC-27, AC-28)")
    func verticalGlyphsAndKinsoku() {
        let sample = "「あー、世界。」…"
        let cells = VerticalLineLayout.layoutVerticalCells(text: sample, maxColumns: 4, rowsPerColumn: 8)
        #expect(!cells.isEmpty)

        // Verify '「' -> '﹁' (U+FE41, rotation 0)
        let openQuote = cells.first { $0.source == "「" }
        #expect(openQuote?.display == "\u{FE41}")
        #expect(openQuote?.rotation == 0)

        // Verify 'ー' -> rotation 90
        let chonpu = cells.first { $0.source == "ー" }
        #expect(chonpu?.display == "ー")
        #expect(chonpu?.rotation == 90)

        // Verify '、' -> '︑' (U+FE11, rotation 0)
        let comma = cells.first { $0.source == "、" }
        #expect(comma?.display == "\u{FE11}")
        #expect(comma?.rotation == 0)

        // Verify '。' -> '︒' (U+FE12, rotation 0)
        let period = cells.first { $0.source == "。" }
        #expect(period?.display == "\u{FE12}")
        #expect(period?.rotation == 0)

        // Verify '」' -> '﹂' (U+FE42, rotation 0)
        let closeQuote = cells.first { $0.source == "」" }
        #expect(closeQuote?.display == "\u{FE42}")
        #expect(closeQuote?.rotation == 0)

        // Verify '…' -> '︙' (U+FE19, rotation 0)
        let ellipsis = cells.first { $0.source == "…" }
        #expect(ellipsis?.display == "\u{FE19}")
        #expect(ellipsis?.rotation == 0)

        // Kinsoku test: place '。' and '」' at row boundary (9th character when rowsPerColumn = 8)
        let kinsokuText = "あいうえおかきく。」さしすせそ"
        let kinsokuCells = VerticalLineLayout.layoutVerticalCells(text: kinsokuText, maxColumns: 4, rowsPerColumn: 8)
        let columnStarts = kinsokuCells.filter { $0.row == 1 && $0.column > 1 }
        for startCell in columnStarts {
            for ch in startCell.source {
                #expect(!VerticalLineLayout.prohibitedLineStartCharacters.contains(ch))
            }
        }
    }

    @Test("Horizontal fallback when line has no Hiragana, Katakana, or Han (AC-30)")
    func horizontalFallbackForLatinAndDigits() {
        let englishLine = "It is a truth universally"
        #expect(VerticalLineLayout.containsJapaneseScript(englishLine) == false)

        let digitsOnly = "1984 - 2026"
        #expect(VerticalLineLayout.containsJapaneseScript(digitsOnly) == false)

        let snapshot = WidgetSnapshot(
            version: 1,
            updatedAt: "2026-10-25T12:00:00Z",
            appearanceID: .default,
            hideOnWidgets: false,
            currentBook: WidgetSnapshotBook(
                id: UUID(),
                title: "Pride and Prejudice",
                author: "Jane Austen",
                isTitlePending: false,
                progressUnit: .page,
                progressDisplay: "p. 12",
                latestLine: englishLine,
                latestLineId: UUID()
            )
        )
        let comp = VerticalLineLayout.composeWidget(snapshot: snapshot)
        #expect(comp.orientation == .horizontal)
        #expect(comp.cells.isEmpty)
        #expect(comp.columnCount == 0)
        #expect(comp.displayedLine == englishLine)
    }

    @Test("VoiceOver accessibility label never contains vertical presentation forms U+FE10..U+FE4F (AC-99)")
    func voiceOverLabelExcludesVerticalForms() {
        let snapshot = WidgetSnapshot(
            version: 1,
            updatedAt: "2026-10-25T12:00:00Z",
            appearanceID: .default,
            hideOnWidgets: false,
            currentBook: WidgetSnapshotBook(
                id: UUID(),
                title: "コンビニ人間",
                author: "村田沙耶香",
                isTitlePending: false,
                progressUnit: .page,
                progressDisplay: "p. 142",
                latestLine: "「世界の部品になることで、わたしはようやく…」",
                latestLineId: UUID()
            )
        )
        let comp = VerticalLineLayout.composeWidget(snapshot: snapshot)
        #expect(comp.orientation == .vertical)
        #expect(comp.accessibilityLabel.contains("コンビニ人間、村田沙耶香"))
        #expect(comp.accessibilityLabel.contains("p. 142"))
        for scalar in comp.accessibilityLabel.unicodeScalars {
            #expect(!(0xFE10...0xFE4F).contains(scalar.value))
        }
    }
}
